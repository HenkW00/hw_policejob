fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'HenkW'
description 'Advanced Police Job using ox_lib'
version '2.0.4'

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
  '/assetpacks',
  'hw_utils'
}

provides {
  'esx_policejob'
}

escrow_ignore {
  'configuration/*.lua',
  'fxmanifest.lua',
  'README.MD'
}