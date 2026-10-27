local audio = {}

local click_source = nil

function audio.init()
    -- Synthesize a 24ms 580Hz warm tactile micro-click
    -- Zero external WAV dependencies; Hann window taper ensures zero DC pop
    local sample_rate = 44100
    local duration = 0.024 -- 24 milliseconds
    local total_samples = math.floor(sample_rate * duration)
    local freq = 580.0

    local sound_data = love.sound.newSoundData(total_samples, sample_rate, 16, 1)

    for i = 0, total_samples - 1 do
        -- Hann taper window: 0.5 * (1 - cos(2*pi*i / N))
        local taper = 0.5 * (1.0 - math.cos(2.0 * math.pi * i / (total_samples - 1)))
        -- Decaying sinusoidal tone
        local t = i / sample_rate
        local wave = math.sin(2.0 * math.pi * freq * t)
        local sample = 0.42 * taper * wave
        sound_data:setSample(i, sample)
    end

    click_source = love.audio.newSource(sound_data, "static")
    click_source:setVolume(0.85)
end

function audio.play_click()
    if click_source then
        click_source:stop()
        click_source:play()
    end
end

return audio
