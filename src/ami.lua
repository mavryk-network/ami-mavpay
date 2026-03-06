return {
    title = 'mavpay',
    commands = {
        info = {
            description = "ami 'info' sub command",
            summary = 'Prints runtime info and status of the app',
            action = '__mavpay/info.lua',
            options = {
                ["services"] = {
                    description = "Prints info about services",
                    type = "boolean"
                },
            },
            context_fail_exit_code = EXIT_APP_INFO_ERROR
        },
        setup = {
            options = {
                configure = {
                    description = 'Configures application, renders templates and installs services'
                }
            },
            action = function(options, _, _, _)
                local no_options = #table.keys(options) == 0
                if no_options or options.environment then
                    am.app.prepare()
                end

                if no_options or not options['no-validate'] then
                    am.execute('validate', { '--platform' })
                end

                if no_options or options.app then
                    am.execute_extension('__mvrk/download-binaries.lua', { context_fail_exit_code = EXIT_SETUP_ERROR })
                end

                if no_options and not options['no-validate'] then
                    am.execute('validate', { '--configuration' })
                end

                if no_options or options.configure then
                    am.execute_extension('__mvrk/create_user.lua', { context_fail_exit_code = EXIT_APP_CONFIGURE_ERROR })
                    am.app.render()
                    am.execute_extension('__mavpay/configure.lua', { context_fail_exit_code = EXIT_APP_CONFIGURE_ERROR })
                end
                log_success('mavpay setup complete.')
            end
        },
        start = {
            description = "ami 'start' sub command",
            summary = 'Starts the mavpay services',
            action = '__mavpay/start.lua',
            context_fail_exit_code = EXIT_APP_START_ERROR
        },
        stop = {
            description = "ami 'stop' sub command",
            summary = 'Stops the mavpay services',
            action = '__mavpay/stop.lua',
            context_fail_exit_code = EXIT_APP_STOP_ERROR
        },
        validate = {
            description = "ami 'validate' sub command",
            summary = 'Validates app configuration and platform support',
            action = function(options, _, _, cli)
                if options.help then
                    am.print_help(cli)
                    return
                end
                log_success('mavpay app configuration validated.')
            end
        },
        continual = {
            description = "ami 'continual' sub command",
            summary = 'Controls mavpay continual service',
            commands = {
                enable = {
                    description = "Enables the continual service.",
                },
                disable = {
                    description = "Disables the continual service.",
                },
                status = {
                    description = "Prints the status of the continual service.",
                }
            },
            action = '__mavpay/continual.lua',
        },
        log = {
            description = "ami 'log' sub command",
            summary = 'Prints logs from services.',
            options = {
                ["follow"] = {
                    aliases = { "f" },
                    description = "Keeps printing the log continuously.",
                    type = "boolean"
                },
                ["end"] = {
                    aliases = { "e" },
                    description = "Jumps to the end of the log.",
                    type = "boolean"
                }
            },
            type = "namespace",
            action = '__mavpay/log.lua',
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        mavpay = {
            description = "mavpay direct passthrough",
            summary = 'Passes any passed arguments directly to mavpay.',
            index = 8,
            type = 'external',
            exec = 'bin/mavpay',
            environment = {
                HOME = os.cwd()
            },
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        pay = {
            description = "mavpay 'pay' passthrough",
            summary = 'Passes any passed arguments directly to mavpay pay.',
            index = 9,
            type = 'external',
            exec = 'bin/mavpay',
            environment = {
                HOME = os.cwd()
            },
            inject_args = { "pay" },
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        ["generate-payouts"] = {
            description = "mavpay 'generate-payouts' passthrough",
            summary = 'Passes any passed arguments directly to mavpay.',
            index = 10,
            type = 'external',
            exec = 'bin/mavpay',
            environment = {
                HOME = os.cwd()
            },
            inject_args = { "generate-payouts" },
            context_fail_exit_code = EXIT_APP_INTERNAL_ERROR
        },
        about = {
            description = "ami 'about' sub command",
            summary = 'Prints information about application',
            action = function(_, _, _, _)
                local about_raw, err = fs.read_file('__mavpay/about.hjson')
                ami_assert(about_raw, 'failed to read about file - error: ' .. tostring(err), EXIT_APP_ABOUT_ERROR)

                local about, err = hjson.parse(about_raw)
                ami_assert(about, 'failed to parse about file - error: ' .. tostring(err), EXIT_APP_ABOUT_ERROR)
                about['App Type'] = am.app.get({ 'type', 'id' }, am.app.get('type'))
                if am.options.OUTPUT_FORMAT == 'json' then
                    print(hjson.stringify_to_json(about, { indent = false, skip_keys = true }))
                else
                    print(hjson.stringify(about))
                end
            end
        },
        version = {
            description = "ami 'version' sub command",
            summary = "Prints versions of binaries used by the app",
            action = "__mvrk/version.lua",
            options = {
                all = {
                    description = "Prent version and all related versions - dependencies, binaries...",
                    type = "boolean"
                }
            }
        },
        remove = {
            index = 7,
            -- // TODO: remove just reports ??
            action = function(options, _, _, _)
                if options.all then
                    am.execute_extension('__mavpay/remove-all.lua', { context_fail_exit_code = EXIT_RM_ERROR })
                    local constants = require "__mavpay/constants"
                    am.app.remove(constants.protected_files)
                    log_success('Application removed.')
                else
                    log_warn "only whole mavpay ami instance can be removed and requires --all parameter"
                end
                return
            end
        }
    }
}
