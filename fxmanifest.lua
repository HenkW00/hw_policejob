fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'HenkW'
description 'ESX Advanced Police Job'
version '2.0.3'

shared_scripts {
  '@ox_lib/init.lua',
  'configuration/*.lua'
}

client_scripts {
  'client/*.lua'
}

server_scripts {
  '@mysql-async/lib/MySQL.lua',
  'server/*.lua',
  'server/version.lua'
}

dependencies {
  'es_extended',
  'mysql-async',
  'ox_lib',
  '/assetpacks'
}

provides {
  'esx_policejob'
}