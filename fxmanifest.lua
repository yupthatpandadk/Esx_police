fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Zematic'
description 'Zematic realistic ESX police system'
version '0.1.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'es_extended',
    'oxmysql'
}
