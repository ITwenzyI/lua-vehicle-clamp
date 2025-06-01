fx_version 'cerulean'
game 'gta5'

description 'Parking claw System'
author 'Kilian'
version '4.0.0'

shared_script 'config.lua'

client_script 'client.lua'
server_script {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}
