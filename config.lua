local config = require('lapis.config')

config({'development', 'staging', 'production'}, {
    postgres = {
        host = os.getenv('DATABASE_URL') or '127.0.0.1:5432',
        user = os.getenv('DATABASE_USERNAME') or 'snap',
        password = os.getenv('DATABASE_PASSWORD') or 'snap-cloud-password',
        database = os.getenv('DATABASE_NAME') or 'snap_cloud'
    },
    session_name = 'snapsession',

    -- Change to the relative (or absolute) path of your disk storage
    -- directory.  Note that the user running Lapis needs to have
    -- read & write permissions to that path.
    store_path = 'store',

    -- for sending email
    mail_user = os.getenv('MAIL_SMTP_USER'),
    mail_password = os.getenv('MAIL_SMTP_PASSWORD'),
    mail_server = os.getenv('MAIL_SMTP_SERVER'),
    mail_from_name = "Snap!Cloud",
    mail_from = "postmaster@snap-cloud.cs10.org",
    mail_footer = "<br/><br/><p><small>Please do not reply to this email. This message was automatically generated by the Snap!Cloud. To contact an actual human being, please write to <a href='mailto:snap-support@bjc.berkeley.edu'>snap-support@bjc.berkeley.edu</a></small></p>",

    worker_connections = os.getenv('WORKER_CONNECTIONS') or 1024,
})

config('development', {
    use_daemon = 'off',
    site_name = 'dev | Snap Cloud',
    hostname = 'localhost',
    port = os.getenv('PORT') or 8080,
    dns_resolver = 'localhost',
    code_cache = 'off',
    num_workers = 1,
    log_directive = 'stderr notice',
    logging = {
        queries = true,
        requests = true
    },
    secret = os.getenv('SESSION_SECRET_BASE') or 'this is a secret',
    measure_performance = true,

    primary_nginx_config = 'development.conf',
    secondary_nginx_config = 'development.conf'
})

config({'production', 'staging'}, {
    hostname = os.getenv('HOSTNAME'),
    secondary_hostname = os.getenv('SECONDARY_HOSTNAME'),
    primary_cert_name = os.getenv('PRIMARY_CERT_NAME'),
    secondary_cert_name = os.getenv('SECONDARY_CERT_NAME'),

    use_daemon = 'on',
    port = os.getenv('PORT') or 80,
    ssl_port = os.getenv('SSL_PORT') or 443,
    dns_resolver = '67.207.67.2 ipv6=off',

    secret = os.getenv('SESSION_SECRET_BASE'),
    code_cache = 'on',

    log_directive = 'logs/error.log warn',

    -- TODO: See if we can turn this on without a big hit
    measure_performance = false
})

config('production', {
    site_name = 'Snap Cloud',
    num_workers = 8,
    primary_nginx_config = 'berkeley-production.conf',
    secondary_nginx_config = 'cs10-production.conf'
})

config('staging', {
    site_name = 'staging | Snap Cloud',
    -- the staging server is a low-cpu server.
    num_workers = 2,
    primary_nginx_config = 'berkeley-staging.conf',
    secondary_nginx_config = 'cs10-staging.conf'
})
