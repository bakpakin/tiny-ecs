local multisource = require "lib.multisource"

local assets = {}

love.graphics.setDefaultFilter("nearest", "nearest")

assets.img_cat = love.graphics.newImage("assets/cat.png")
assets.img_catandcannon = love.graphics.newImage("assets/catandcannon.png")
assets.img_gun = love.graphics.newImage("assets/gun.png")
assets.img_bullet = love.graphics.newImage("assets/bullet.png")
assets.img_explosion = love.graphics.newImage("assets/explosion.png")
assets.img_pig = love.graphics.newImage("assets/pig.png")
assets.img_spawner = love.graphics.newImage("assets/spawner.png")

assets.snd_catjump = multisource.new(love.audio.newSource("assets/catjump.wav"))
assets.snd_cannon = multisource.new(love.audio.newSource("assets/cannon.wav"))
assets.snd_thud = multisource.new(love.audio.newSource("assets/thud.wav"))
assets.snd_meow = multisource.new(love.audio.newSource("assets/meow.ogg"))
assets.snd_oink = multisource.new(love.audio.newSource("assets/oink.ogg"))
assets.snd_yay = multisource.new(love.audio.newSource("assets/yay.wav"))

assets.snd_music = love.audio.newSource("assets/music.ogg")

assets.fnt_hud = love.graphics.newFont("assets/font.ttf", 48)
assets.fnt_smallhud = love.graphics.newFont("assets/font.ttf", 32)
assets.fnt_reallysmallhud = love.graphics.newFont("assets/font.ttf", 24)


return assets