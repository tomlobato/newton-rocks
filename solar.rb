#!/usr/bin/env ruby

require 'mittsu'
require_relative './mechanics'

class Solar
    SCREEN_WIDTH = 1600
    SCREEN_HEIGHT = 1200
    ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f
    DIAMETER_SCALE = 1e7
    DIAMETER_FACTOR = {
        sun:     4e-3,
        mercury: 1,
        venus:   1,
        earth:   1,
        moon:    1,
        mars:    1,
        jupiter: 0.7,
        saturn:  0.7,
        uranus:  1,
        neptune: 1,
        pluto:   1,
    }

    def initialize mechanics
        @mechanics = mechanics
        @scene = Mittsu::Scene.new
        @camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)
        @camera.position.z = 30.0
        @renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: 'Solar System'
    end

    def run
        build

        dat = @mechanics.dat
        Thread.new do
            @mechanics.run
        end

        @renderer.window.on_resize do |width, height|
            @renderer.set_viewport(0, 0, width, height)
            @camera.aspect = width.to_f / height.to_f
            @camera.update_projection_matrix
        end

        norm = normalize_orbit

        @renderer.window.run do
            @astros.each_with_index do |astro, idx|
                astro.position.set(      
                    dat[0][idx][2] / norm,
                    dat[0][idx][3] / norm,
                    dat[0][idx][4] / norm 
                )
                astro.rotation.z += 0.01
            end
            @renderer.render(@scene, @camera)
            sleep 0.01
        end
    end

    private

    def build
        light = Mittsu::HemisphereLight.new(0xffffff, 0x000000, 1)
        light.position.z = 0
        @scene.add(light)

        @astros = []

        @mechanics.info.each_pair do |k, info|
            geometry = Mittsu::SphereGeometry.new(diameter(k, info), 32, 16)
            texture = Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), "./assets/#{k}.png")
            material = Mittsu::MeshLambertMaterial.new(map: texture)

            astro = Mittsu::Mesh.new(geometry, material)
            @scene.add(astro)

            @astros << astro
        end
    end

    def diameter name, info
        DIAMETER_FACTOR[name] * info[:diameter] / DIAMETER_SCALE
    end

    def normalize_orbit
        largest_orbit = 0
        @mechanics.info.each_value{|v| 
            if v[:distance_to_sun] > largest_orbit
                largest_orbit = v[:distance_to_sun]
            end
        } 
        largest_orbit / 30.0        
    end

end

mechanics = Mechanics.new
Solar.new(mechanics).run
