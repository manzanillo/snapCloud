-- API module
-- ==========
-- See static/API for API description
--
-- written by Bernat Romagosa
--
-- Copyright (C) 2017 by Bernat Romagosa
--
-- This file is part of Snap Cloud.
--
-- Snap Cloud is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local app = package.loaded.app
local db = package.loaded.db
local app_helpers = package.loaded.db
local capture_errors = package.loaded.capture_errors
local yield_error = package.loaded.yield_error
local validate = package.loaded.validate
local bcrypt = package.loaded.bcrypt
local Model = package.loaded.Model
local util = package.loaded.util
local respond_to = package.loaded.respond_to
local json_params = package.loaded.json_params
local Users = package.loaded.Users
local Projects = package.loaded.Projects

require 'disk'
require 'responses'
require 'validation'


-- API Endpoints
-- =============

app:match('users', '/users', respond_to({
    -- Methods:     GET
    -- Description: Get a list of users. Returns an empty list if no parameters provided,
    --              except when the query issuer is an admin.
    -- Parameters:  matchtext, page, pagesize

    OPTIONS = cors_options,
    GET = function (self)
        -- TODO: security, filters and pagination
        return jsonResponse(Users:select({ fields = 'username' }))
    end
}))

app:match('current_user', '/users/c', respond_to({

    -- Methods:     GET
    -- Description: Get the currently logged user's username.

    OPTIONS = cors_options,
    GET = function (self)
        return jsonResponse({ username = self.session.username })
    end
}))

app:match('user', '/users/:username', respond_to({
    -- Methods:     GET, DELETE, POST
    -- Description: Get info about a user, or delete/add/update a user.

    OPTIONS = cors_options,
    GET = function (self)
        return jsonResponse(
            Users:select(
                'where username = ?',
                self.params.username,
                { fields = 'username, location, about, joined' })[1])
    end,

    DELETE = capture_errors(function (self)

        assert_all({'logged_in', 'admin'}, self)

        if not (user:delete()) then
            yield_error('Could not delete user ' .. self.params.username)
        else
            return okResponse('User ' .. self.params.username .. ' has been removed.')
        end
    end),

    POST = capture_errors(function (self)
        validate.assert_valid(self.params, {
            { 'username', exists = true, min_length = 4, max_length = 200 },
            { 'password', exists = true, min_length = 6 },
            { 'password_repeat', equals = self.params.password, 'passwords do not match' },
            { 'email', exists = true, min_length = 5 },
        })

        if Users:find(self.params.username) then
            yield_error('User ' .. self.params.username .. ' already exists');
        end

        Users:create({
            username = self.params.username,
            password = bcrypt.digest(self.params.password, 11),
            email = self.params.email,
            isadmin = false,
            joined = db.format_date()
        })

        return okResponse('User ' .. self.params.username .. ' created')
    end)

}))

app:match('login', '/users/:username/login', respond_to({
    -- Methods:     POST
    -- Description: Logs a user into the system.
    -- Parameters:  password

    OPTIONS = cors_options,
    POST = capture_errors(function (self)
        local user = Users:find(self.params.username)

        if not user then yield_error(err.nonexistentUser) end

        if (bcrypt.verify(self.params.password, user.password)) then
            self.session.username = user.username
            return okResponse('User ' .. self.params.username .. ' logged in')
        else
            yield_error('invalid password')
        end
    end)
}))

app:match('logout', '/users/:username/logout', respond_to({
    -- Methods:     POST
    -- Description: Logs out a user from the system.

    OPTIONS = cors_options,
    POST = capture_errors(function (self)
        assert_users_match(self)
        self.session.username = ''
        return okResponse('user ' .. self.params.username .. ' logged out')
    end)
}))


app:match('projects', '/projects', respond_to({
    -- Methods:     GET
    -- Description: Get a list of published projects. Returns an empty list if no parameters
    --              provided, except when the query issuer is an admin.
    -- Parameters:  updatedrange, publishedrange, page, pagesize, matchtext.

    OPTIONS = cors_options,
    GET = function (self)
        -- TODO
    end
}))

app:match('user_projects', '/projects/:username', respond_to({
    -- Methods:     GET
    -- Description: Get all projects by a user.
    --              Response will depend on parameters and query issuer permissions.
    -- Parameters:  ispublished, publishedrange, updatedrange, page, pagesize, matchtext

    OPTIONS = cors_options,
    GET = function (self)
        assert_all({'user_exists', 'users_match'}, self)
        return jsonResponse(Projects:select('where username = ?', self.params.username))
    end
}))

app:match('project', '/projects/:username/:projectname', respond_to({
    -- Methods:     GET, DELETE, POST
    -- Description: Get/delete/add/update a particular project.
    --              Response will depend on query issuer permissions.
    -- Parameters:  ispublic, ispublished
    -- Body:        xml, notes, thumbnail

    OPTIONS = cors_options,
    GET = capture_errors(function (self)
        -- TODO: what to do with project media?
        local project = Projects:find(self.params.username, self.params.projectname)
        assert_all({'project_exists', 'user_exists', 'users_match'}, self)
        return rawResponse(retrieveFromDisk(project.id, 'project.xml'))
    end),
    DELETE = capture_errors(function (self)
        assert_all({'project_exists', 'user_exists', 'users_match'}, self)
        local project = Projects:find(self.params.username, self.params.projectname)
        deleteDirectory(project.id)
        if not (project:delete()) then
            yield_error('Could not delete user ' .. self.params.username)
        else
            return okResponse('User ' .. self.params.username .. ' has been removed.')
        end
    end),
    POST = capture_errors(function (self)
        validate.assert_valid(self.params, {
            { 'projectname', exists = true },
            { 'username', exists = true }
        })

        assert_all({'user_exists', 'users_match'}, self)

        -- Read request body and parse it into JSON
        ngx.req.read_body()
        local body_data = ngx.req.get_body_data()
        local body = body_data and util.from_json(body_data) or nil

        if (not body.xml) then
            yield_error('Empty project contents')
        end

        local project = Projects:find(self.params.username, self.params.projectname)

        if (project) then
            local shouldUpdateSharedDate =
                ((not project.lastshared and self.params.ispublished)
                or (self.params.ispublished and not project.ispublished))

            project:update({
                lastupdated = db.format_date(),
                lastshared = shouldUpdateSharedDate and db.format_date() or nil,
                notes = body.notes,
                ispublic = self.params.ispublic,
                ispublished = self.params.ispublished
            })
        else
            Projects:create({
                projectname = self.params.projectname,
                username = self.params.username,
                lastupdated = db.format_date(),
                lastshared = self.params.ispublished and db.format_date() or nil,
                notes = body.notes,
                ispublic = self.params.ispublic,
                ispublished = self.params.ispublished
            })
            project = Projects:find(self.params.username, self.params.projectname)
        end

        saveToDisk(project.id, 'project.xml', body.xml)
        saveToDisk(project.id, 'thumbnail', body.thumbnail)
        saveToDisk(project.id, 'media.xml', body.media)

        if not (retrieveFromDisk(project.id, 'project.xml')
            and retrieveFromDisk(project.id, 'thumbnail')
            and retrieveFromDisk(project.id, 'media.xml')) then
            project:delete()
            yield_error('Could not save project ' .. self.params.projectname)
        else
            return okResponse('project ' .. self.params.projectname .. ' saved')
        end

    end)
}))

app:match('project_meta', '/projects/:username/:projectname/metadata', respond_to({
    -- Methods:     GET, DELETE, POST
    -- Description: Get/delete/add/update a project metadata.
    -- Parameters:  projectname, ispublic, ispublished, lastupdated, lastshared.
    -- Body:        notes, projectname

    OPTIONS = cors_options,
    GET = capture_errors(function (self)
        -- TODO
    end),
    DELETE = capture_errors(function (self)
        -- TODO
    end),
    POST = capture_errors(function (self)
        assert_all({'user_exists', 'users_match'}, self)

        local project = Projects:find(self.params.username, self.params.projectname)
        if not project then yield_error(err.nonexistentProject) end

        local shouldUpdateSharedDate =
            ((not project.lastshared and self.params.ispublished)
            or (self.params.ispublished and not project.ispublished))

        -- Read request body and parse it into JSON
        ngx.req.read_body()
        local body_data = ngx.req.get_body_data()
        local body = body_data and util.from_json(body_data) or nil
        local new_name = body and body.projectname or nil
        local new_notes = body and body.notes or nil

        project:update({
            projectname = new_name or project.projectname,
            lastupdated = db.format_date(),
            lastshared = shouldUpdateSharedDate and db.format_date() or nil,
            notes = new_notes or project.notes,
            ispublic = self.params.ispublic or project.ispublic,
            ispublished = self.params.ispublished or project.ispublished
        })

        return okResponse('project ' .. self.params.projectname .. ' updated')
    end)
}))

app:match('project_thumb', '/projects/:username/:projectname/thumbnail', respond_to({
    -- Methods:     GET
    -- Description: Get a project thumbnail.

    OPTIONS = cors_options,
    GET = capture_errors(function (self)
        local project = Projects:find(self.params.username, self.params.projectname)
        if not project then yield_error(err.nonexistentProject) end

        if self.params.username ~= self.session.username
            and not project.ispublic then
            yield_error(err.auth)
        end

        return rawResponse(retrieveFromDisk(project.id, 'thumbnail'))
    end)
}))