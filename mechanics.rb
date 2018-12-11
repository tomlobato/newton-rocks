#!/usr/bin/env ruby

class Mechanics
    G = 6.67408e-11
    UA = 1.496e11

    def initialize
        @info = load_info        
        @dat = []
        @info.each_pair do |k, v|
            @dat << [v[:name], v[:mass], 
                     v[:sun_distance], 0, 0, # x y z
                     0, v[:orbit_speed], 0]  # v
        end
        @dat = [@dat.dup, @dat.dup]
    end

    def dat
        @dat
    end

    def info
        @info
    end

    def run
        year_in = 20
        total_time = 365 * 24 * 3600.0 # 1 ano
        t = 0.0
        dt = 100
        didx = 0

        # (total_time/dt).to_i.times 
        loop do |loop_num|
            (0...@dat[0].size).each do |i|
                ax = 0
                ay = 0
                az = 0
                (0...@dat[0].size).each do |j|
                    next if i == j
                    d = ( (@dat[didx][i][2]-@dat[didx][j][2])**2 + 
                        (@dat[didx][i][3]-@dat[didx][j][3])**2 + 
                        (@dat[didx][i][4]-@dat[didx][j][4])**2 )**0.5
                    ax += -1 * G * @dat[didx][j][1] * (@dat[didx][i][2]-@dat[didx][j][2]) / d**3
                    ay += -1 * G * @dat[didx][j][1] * (@dat[didx][i][3]-@dat[didx][j][3]) / d**3
                    az += -1 * G * @dat[didx][j][1] * (@dat[didx][i][4]-@dat[didx][j][4]) / d**3
                end
                didx2 = didx == 0 ? 1 : 0

                @dat[didx2][i][5] = @dat[didx][i][5] + ax * dt
                @dat[didx2][i][6] = @dat[didx][i][6] + ay * dt
                @dat[didx2][i][7] = @dat[didx][i][7] + az * dt

                @dat[didx2][i][2] = @dat[didx][i][2] + (@dat[didx][i][5] + ax * dt / 2.0) * dt
                @dat[didx2][i][3] = @dat[didx][i][3] + (@dat[didx][i][6] + ay * dt / 2.0) * dt
                @dat[didx2][i][4] = @dat[didx][i][4] + (@dat[didx][i][7] + az * dt / 2.0) * dt
            end
            t += dt
            # break if t >= total_time
            # puts loop_num if loop_num % 100_000 == 0
            didx = didx == 0 ? 1 : 0
            sleep 0.0001
        end

        puts "final:"
        puts @dat[didx]
        puts "/final:"
    end

    def load_info
        info = {}

        # https://en.wikipedia.org/wiki/Sun
        info[:sun] = {
            name: 'Sun',
            mass: 1.9885e30,
            diameter: 696_392_000,
            sun_distance: 0,
            orbit_speed: 0,
        }

        # https://nssdc.gsfc.nasa.gov/planetary/factsheet/
        raw = 
            "MERCURY 	 VENUS 	 EARTH 	 MOON 	 MARS 	 JUPITER 	 SATURN 	 URANUS 	 NEPTUNE 	 PLUTO 
            0.330	4.87	5.97	0.073	0.642	1898	568	86.8	102	0.0146
            4879	12,104	12,756	3475	6792	142,984	120,536	51,118	49,528	2370
            5427	5243	5514	3340	3933	1326	687	1271	1638	2095
            3.7	8.9	9.8	1.6	3.7	23.1	9.0	8.7	11.0	0.7
            4.3	10.4	11.2	2.4	5.0	59.5	35.5	21.3	23.5	1.3
            1407.6	-5832.5	23.9	655.7	24.6	9.9	10.7	-17.2	16.1	-153.3
            4222.6	2802.0	24.0	708.7	24.7	9.9	10.7	17.2	16.1	153.3
            57.9	108.2	149.6	0.384*	227.9	778.6	1433.5	2872.5	4495.1	5906.4
            46.0	107.5	147.1	0.363*	206.6	740.5	1352.6	2741.3	4444.5	4436.8
            69.8	108.9	152.1	0.406*	249.2	816.6	1514.5	3003.6	4545.7	7375.9
            88.0	224.7	365.2	27.3	687.0	4331	10,747	30,589	59,800	90,560
            47.4	35.0	29.8	1.0	24.1	13.1	9.7	6.8	5.4	4.7
            7.0	3.4	0.0	5.1	1.9	1.3	2.5	0.8	1.8	17.2
            0.205	0.007	0.017	0.055	0.094	0.049	0.057	0.046	0.011	0.244
            0.034	177.4	23.4	6.7	25.2	3.1	26.7	97.8	28.3	122.5
            167	464	15	-20	-65	-110	-140	-195	-200	-225
            0	92	1	0	0.01	Unknown*	Unknown*	Unknown*	Unknown*	0.00001
            0	0	1	0	2	79	62	27	14	5
            No	No	No	No	No	Yes	Yes	Yes	Yes	No
            Yes	No	Yes	No	No	Yes	Yes	Yes	Yes	Unknown"
        
        mat = []

        raw.strip.split(/\s*\n+\s*/).each do |line|
            mat << line.strip.gsub(',', '').split(/\s+/)
        end

        mat.transpose.each do |line|
            next if %w(MOON JUPITER SATURN URANUS NEPTUNE PLUTO).include?(line[0])
            # MERCURY VENUS EARTH MARS     
            mass = line[1].to_f
            diameter = line[2].to_f
            sun_distance = line[8].to_f
            orbit_speed = line[12].to_f
            orbit_inclination = line[13].to_f

            mass *= 1e24 # kg
            diameter *= 1e3 # m
            sun_distance *= 1e9 # m
            orbit_speed *= 1e3 # m/s

            info[line[0].downcase.to_sym] = {
                name: line[0].capitalize,
                mass: mass,
                diameter: diameter,
                sun_distance: sun_distance,
                orbit_speed: orbit_speed,
            }
        end

        info
    end
end

