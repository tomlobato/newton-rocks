#!/usr/bin/env ruby

require 'mittsu'
require_relative './mechanics'

class Solar
    SCREEN_WIDTH = 1600
    SCREEN_HEIGHT = 1200
    ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

    def initialize mechanics
        @mechanics = mechanics
        @scene = Mittsu::Scene.new
        @camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)
        @camera.position.z = 30.0
        @renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: 'Solar System'
    end

    def build
        light = Mittsu::HemisphereLight.new(0xffffff, 0x000000, 1)
        light.position.z = 0
        @scene.add(light)

        @aobjs = []

        @mechanics.info.each_pair do |k, info|
            # jupiter_diameter = 142_984_000.0
            earth_diameter = 12_756_000.0
            diameter = info[:diameter] / earth_diameter
            diameter = 1.2 if k == :sun

            container = Mittsu::Object3D.new
            geometry = Mittsu::SphereGeometry.new(diameter, 32, 16)
            texture = Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), "./assets/#{k}.png")
            material = Mittsu::MeshLambertMaterial.new(map: texture) #, opacity: 0.3, transparent: true)
            aobj = Mittsu::Mesh.new(geometry, material)
            container.add(aobj)
            @scene.add(container)

            @aobjs << aobj
        end
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

        biggest = 0 # SolarCore::UA
        @mechanics.info.each_value{|v| biggest = v[:sun_distance] if v[:sun_distance] > biggest }
        div = biggest / 20.0

        @renderer.window.run do
            @aobjs.each_with_index do |aobj, idx|
                aobj.position.set(      
                    dat[0][idx][2] / div,
                    dat[0][idx][3] / div,
                    dat[0][idx][4] / div 
                )
            end
            @renderer.render(@scene, @camera)
            sleep 0.01
        end
    end

end

mechanics = Mechanics.new
Solar.new(mechanics).run
