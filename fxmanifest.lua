fx_version 'cerulean'
game 'gta5'

description 'Riot Truck Job'
author 'Riot Scripts Dev'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/ui.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png',
    'html/img/vehicles/*.png',
}

lua54 'yes' 