local db = require('lapis.db')
local schema = require('lapis.db.schema')
local types = schema.types

return {
    [00000001] = function()
        --[[
            The initial lapis schema was written after a plain sql version
            if_not_exists is used for compatibility, but it can be removed
            after the production instances are updated.
        ]]

        db.query([[
            CREATE FUNCTION expire_token() RETURNS trigger
                LANGUAGE plpgsql
                AS $$
BEGIN
  DELETE FROM tokens WHERE created < NOW() - INTERVAL '3 days';
RETURN NEW;
END;
$$;
        ]])

        schema.create_table('users', {
            {'id', types.serial},
            {'username', types.text({ primary_key = true })},
            {'created', types.time({ timezone = true, null = true  })},
            {'email', types.text({ null = true })},
            {'salt', types.text({ null = true })},
            {'password', types.text({ null = true })},
            {'about', types.text({ null = true })},
            {'location', types.text({ null = true })},
            {'isadmin', types.boolean({ null = true })},
            {'verified', types.boolean({ null = true })}

        }, { if_not_exists = true })

        schema.create_table('projects', {
            {'id', types.serial},
            {'projectname', types.text},
            {'ispublic', types.boolean({ null = true })},
            {'ispublished', types.boolean({ null = true })},
            {'notes', types.text({ null = true })},
            {'created', types.time({ timezone = true, null = true  })},
            {'lastupdated', types.time({ timezone = true, null = true  })},
            {'lastshared', types.time({ timezone = true, null = true })},
            {'username', types.text},
            {'firstpublished', types.time({ timezone = true, null = true })},
            {'remixes', types.integer({ array = true, null = true })},

            "PRIMARY KEY (username, projectname)",
            "FOREIGN KEY (username) REFERENCES users"
        }, { if_not_exists = true })

        schema.create_table('tokens', {
            {'created', types.time({ default = db.raw('now()')  })},
            {'username', types.text},
            {'purpose', types.text({ null = true })},
            {'value', types.text({ primary_key = true })},

            "FOREIGN KEY (username) REFERENCES users"
        }, { if_not_exists = true })

        db.query('CREATE TRIGGER expire_token_trigger AFTER INSERT ON tokens FOR EACH STATEMENT EXECUTE PROCEDURE expire_token()')
     end --,

     -- [00000100] = function()
     --     schema.rename_column('users', 'created', 'created_at')
     --     schema.rename_column('projects', 'created', 'created_at')
     --     schema.rename_column('tokens', 'created', 'created_at')
     --     schema.rename_column('projects', 'lastupdated', 'updated_at')
     --     schema.rename_column('projects', 'lastshared', 'shared_at')
     --     schema.rename_column('projects', 'firstpublished', 'published_at')
     -- end,
     --
     -- [00000101] = function()
     --     schema.add_column(
     --         'users', 'updated_at', types.time({ timezone = true, null = true })
     --     )
     -- end
}