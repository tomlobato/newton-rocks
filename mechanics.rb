#!/usr/bin/env ruby

class Mechanics
    G = 6.67408e-11
    # MOON MERCURY VENUS EARTH MARS JUPITER SATURN URANUS NEPTUNE PLUTO
    EXCLUDE_ASTROS = %w(MOON)
    DT = 300 # Time step between loop iterations
    LOOP_WAIT = 0.00001
    DEBUG = false

    def initialize
        @info = load_info        
        @dat = load_dat
    end

    def dat
        @dat
    end

    def info
        @info
    end

    def run
        didx = 0

        start_watcher
        stat_cnt = 0
        stat = 0
        loop do |loop_num|
            t0 = Time.now if DEBUG
            dat  = @dat[didx]
            dat2 = @dat[didx == 0 ? 1 : 0]
            
            (0...dat.size).each do |i|
                # Calculates acceleration of astro i 
                # caused by all other astros
                # (for faster computation it sums the delta velocity 
                # per axis instead pure acceleration)
                dvx = 0
                dvy = 0
                dvz = 0

                (0...dat.size).each do |j|
                    next if i == j

                    dx = dat[i][2] - dat[j][2]
                    dy = dat[i][3] - dat[j][3]
                    dz = dat[i][4] - dat[j][4]

                    factor = -1 * G * dat[j][1] * DT / (dx**2 + dy**2 + dz**2)**1.5

                    # Delta velocity for each axis
                    dvx += factor * dx
                    dvy += factor * dy
                    dvz += factor * dz
                end

                # Velocity change for i
                dat2[i][5] = dat[i][5] + dvx
                dat2[i][6] = dat[i][6] + dvy
                dat2[i][7] = dat[i][7] + dvz

                # Position change for i
                dat2[i][2] = dat[i][2] + (dat[i][5] + dvx/2) * DT
                dat2[i][3] = dat[i][3] + (dat[i][6] + dvy/2) * DT
                dat2[i][4] = dat[i][4] + (dat[i][7] + dvz/2) * DT
            end
            
            didx = didx == 0 ? 1 : 0
            if DEBUG
                stat += (Time.now - t0)
                stat_cnt += 1
                puts (1e6*stat/stat_cnt) if stat_cnt % 1e5 == 0
            end
            sleep LOOP_WAIT
        end
    end

    private

    def load_info
        info = {}

        # https://en.wikipedia.org/wiki/Sun
        info[:sun] = {
            name: 'Sun',
            mass: 1.9885e30,
            diameter: 696_392_000,
            distance_to_sun: 0,
            orbit_speed: 0,
        }

        # https://nssdc.gsfc.nasa.gov/planetary/factsheet/
        raw = 
            "MERCURY	VENUS	EARTH	MOON	MARS	JUPITER	SATURN	URANUS	NEPTUNE	PLUTO	
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
            next if EXCLUDE_ASTROS.include?(line[0])

            info[line[0].downcase.to_sym] = {
                name:               line[0].capitalize,
                mass:               line[1].to_f  * 1e24, # to kg
                diameter:           line[2].to_f  * 1e3,  # to m
                distance_to_sun:    line[8].to_f  * 1e9,  # to m
                orbit_speed:        line[12].to_f * 1e3,  # to m/s
                orbit_inclination:  line[13].to_f,
            }
        end

        if DEBUG
            require 'json'
            puts info.to_json
        end

        info
    end

    def load_dat
        dat = []

        # Sets array @dat with astro informations and initial states
        @info.each_pair do |k, v|
            dat << [
                v[:name],               # 0 name
                v[:mass],               # 1 mass

                v[:distance_to_sun],    # 2 x coordinate
                0,                      # 3 y coordinate
                0,                      # 4 z coordinate

                0,                      # 5 x speed
                v[:orbit_speed],        # 6 y speed
                0                       # 7 z speed
            ]
        end

        # Duplicates dat. 
        # Each loop iteration reads from one copy 
        # and writes to the other, then inverts the index for 
        # the next iteration
        [dat.dup, dat.dup]        
    end

    def start_watcher
        @init = @dat[0].dup
    end

    def report_changes
        @dat[0].each{|f| print "#{f[0]}\t" }        
        @dat[0].each_with_index{|f, i| report f, i }        
    end

    def report f, i
        @init[i][2]
        print "#{rep}\t"
    end

end

