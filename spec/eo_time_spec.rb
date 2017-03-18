# encoding: UTF-8

#
# Specifying EtOrbi
#
# Wed Mar 11 21:17:36 JST 2015, quatre ans... (rufus-scheduler)
# Sun Mar 19 05:16:28 JST 2017
#

require 'spec_helper'


describe EtOrbi::EoTime do

  describe '.get_tzone' do

    def gtz(s); z = EtOrbi::EoTime.get_tzone(s); z ? z.name : z; end

    it 'returns a tzone for all the know zone strings' do

      expect(gtz('GB')).to eq('GB')
      expect(gtz('UTC')).to eq('UTC')
      expect(gtz('GMT')).to eq('GMT')
      expect(gtz('Zulu')).to eq('Zulu')
      expect(gtz('Japan')).to eq('Japan')
      expect(gtz('Turkey')).to eq('Turkey')
      expect(gtz('Asia/Tokyo')).to eq('Asia/Tokyo')
      expect(gtz('Europe/Paris')).to eq('Europe/Paris')
      expect(gtz('Europe/Zurich')).to eq('Europe/Zurich')
      expect(gtz('W-SU')).to eq('W-SU')

      expect(gtz('PST')).to eq('America/Dawson')
      expect(gtz('CEST')).to eq('Africa/Ceuta')

      expect(gtz('Z')).to eq('Zulu')

      expect(gtz('+09:00')).to eq('+09:00')
      expect(gtz('-01:30')).to eq('-01:30')

      expect(gtz('+08:00')).to eq('+08:00')
      expect(gtz('+0800')).to eq('+0800') # no normalization to "+08:00"

      expect(gtz(3600)).to eq('+01:00')
    end

    it 'returns nil for unknown zone names' do

      expect(gtz('Asia/Paris')).to eq(nil)
      expect(gtz('Nada/Nada')).to eq(nil)
      expect(gtz('7')).to eq(nil)
      expect(gtz('06')).to eq(nil)
      expect(gtz('sun#3')).to eq(nil)
      expect(gtz('Mazda Zoom Zoom Stadium')).to eq(nil)
    end

    # gh-222
    it "falls back to ENV['TZ'] if it doesn't know Time.now.zone" do

      begin

        current = EtOrbi::EoTime.get_tzone(:current)

        class ::Time
          alias _original_zone zone
          def zone; "中国标准时间"; end
        end

#        expect(
#          EtOrbi::EoTime.get_tzone(:current)
#        ).to eq(nil)
#
#        expect(
#          EtOrbi::EoTime.get_tzone(:current)
#        ).to eq(
#          EtOrbi::EoTime.get_tzone(Time.now.zone)
#        )
  #
  # gh-240 introduces a way of finding the timezone by asking directly
  # to the system, so those do return a timezone...

        in_zone 'Asia/Shanghai' do

          expect(
            EtOrbi::EoTime.get_tzone(:current)
          ).to eq(
            EtOrbi::EoTime.get_tzone('Asia/Shanghai')
          )
        end

      ensure

        class ::Time
          def zone; _original_zone; end
        end
      end

      expect(
        EtOrbi::EoTime.get_tzone(:current)
      ).to eq(
        current
      )
    end

    [ # for gh-228

      [ 'Asia/Tokyo', 'Asia/Tokyo' ],
      [ 'Asia/Shanghai', 'Asia/Shanghai' ],
      [ 'Europe/Zurich', 'Europe/Zurich' ],
      [ 'Europe/London', 'Europe/London' ]

    ].each do |zone, target|

      it "returns the current timezone for :current in #{zone}" do

        in_zone(zone) do

          expect(
            EtOrbi::EoTime.get_tzone(:current)
          ).to eq(
            EtOrbi::EoTime.get_tzone(target)
          )
        end
      end
    end

#    it 'flips burgers' do
#      p Rufus::Scheduler::CronLine.new('* * * * *').to_a
#      p EtOrbi::EoTime.get_tzone(:current)
#      in_zone 'Asia/Shanghai' do
#        p ENV['TZ']
#        p Rufus::Scheduler::CronLine.new('* * * * *').to_a
#        p EtOrbi::EoTime.get_tzone(:current)
#      end
#      ENV['TZ'] = 'Asia/Shanghai'
#      p Rufus::Scheduler::CronLine.new('* * * * *').to_a
#      #p EtOrbi::EoTime.get_tzone('Asia/Shanghai')
#      #p EtOrbi::EoTime.get_tzone('America/Bahia_Banderas')
#      #p EtOrbi::EoTime.get_tzone('Asia/Shanghai').now
#      #p EtOrbi::EoTime.get_tzone('America/Bahia_Banderas').now
#      p EtOrbi::EoTime.get_tzone(:current)
#    end
  end

  describe '.new' do

    it 'accepts an integer' do

      zt = EtOrbi::EoTime.new(1234567890, 'America/Los_Angeles')

      expect(zt.seconds.to_i).to eq(1234567890)
    end

    it 'accepts a float' do

      zt = EtOrbi::EoTime.new(1234567890.1234, 'America/Los_Angeles')

      expect(zt.seconds.to_i).to eq(1234567890)
    end

    it 'accepts a Time instance' do

      zt =
        EtOrbi::EoTime.new(
          Time.utc(2007, 11, 1, 15, 25, 0),
          'America/Los_Angeles')

      expect(zt.seconds.to_i).to eq(1193930700)
    end
  end

  describe '.parse' do

    it 'parses a time string without a timezone' do

      zt =
        in_zone('Europe/Moscow') {
          EtOrbi::EoTime.parse('2015/03/08 01:59:59')
        }

      t = zt
      u = zt.utc

      expect(t.to_i).to eq(1425769199)
      expect(u.to_i).to eq(1425769199)

      expect(t.strftime('%Y/%m/%d %H:%M:%S %Z %z') + " #{t.isdst}"
        ).to eq('2015/03/08 01:59:59 MSK +0300 false')

      expect(u.to_debug_s).to eq('t 2015-03-07 22:59:59 +00:00 dst:false')
    end

    it 'parses a time string with a full name timezone' do

      zt =
        EtOrbi::EoTime.parse(
          '2015/03/08 01:59:59 America/Los_Angeles')

      t = zt
      u = zt.utc

      expect(t.to_i).to eq(1425808799)
      expect(u.to_i).to eq(1425808799)

      expect(t.to_debug_s).to eq('zt 2015-03-08 01:59:59 -08:00 dst:false')
      expect(u.to_debug_s).to eq('t 2015-03-08 09:59:59 +00:00 dst:false')
    end

    it 'parses a time string with a delta timezone' do

      zt =
        in_zone('Europe/Berlin') {
          EtOrbi::EoTime.parse('2015-12-13 12:30 -0200')
        }

      t = zt
      u = zt.utc

      expect(t.to_i).to eq(1450017000)
      expect(u.to_i).to eq(1450017000)

      expect(t.to_debug_s).to eq('zt 2015-12-13 12:30:00 -02:00 dst:false')
      expect(u.to_debug_s).to eq('t 2015-12-13 14:30:00 +00:00 dst:false')
    end

    it 'parses a time string with a delta (:) timezone' do

      zt =
        in_zone('Europe/Berlin') {
          EtOrbi::EoTime.parse('2015-12-13 12:30 -02:00')
        }

      t = zt
      u = zt.utc

      expect(t.to_i).to eq(1450017000)
      expect(u.to_i).to eq(1450017000)

      expect(t.to_debug_s).to eq('zt 2015-12-13 12:30:00 -02:00 dst:false')
      expect(u.to_debug_s).to eq('t 2015-12-13 14:30:00 +00:00 dst:false')
    end

    it 'takes the local TZ when it does not know the timezone' do

      in_zone 'Europe/Moscow' do

        zt = EtOrbi::EoTime.parse('2015/03/08 01:59:59 Nada/Nada')

        expect(zt.zone.name).to eq('Europe/Moscow')
      end
    end

    it 'fails on invalid strings' do

      expect {
        EtOrbi::EoTime.parse('xxx')
      }.to raise_error(
        ArgumentError, 'no time information in "xxx"'
      )
    end
  end

  describe '.make' do

    it 'accepts a Time' do

      expect(
        EtOrbi::EoTime.make(
          Time.utc(2016, 11, 01, 12, 30, 9)).to_debug_s
      ).to eq(
        'zt 2016-11-01 12:30:09 +00:00 dst:false'
      )
    end

    it 'accepts a Date' do

      expect(
        EtOrbi::EoTime.make(
          Date.new(2016, 11, 01))
      ).to eq(
        EtOrbi::EoTime.new(
          Time.local(2016, 11, 01).to_f, nil)
      )
    end

    it 'accepts a String' do

      expect(
        EtOrbi::EoTime.make(
          '2016-11-01 12:30:09')
      ).to eq(
        EtOrbi::EoTime.new(
          Time.local(2016, 11, 01, 12, 30, 9).to_f, nil)
      )
    end

    it 'accepts a String (Zulu)' do

      expect(
        EtOrbi::EoTime.make(
          '2016-11-01 12:30:09Z')
      ).to eq(
        EtOrbi::EoTime.new(
          Time.utc(2016, 11, 01, 12, 30, 9).to_f, 'Zulu')
      )
    end

    it 'accepts a String (ss+01:00)' do

      expect(
        EtOrbi::EoTime.make('2016-11-01 12:30:09+01:00').to_debug_s
      ).to eq(
        'zt 2016-11-01 12:30:09 +01:00 dst:false'
      )
    end

    it 'accepts a String (ss-01)' do

      expect(
        EtOrbi::EoTime.make('2016-11-01 12:30:09-01').to_debug_s
      ).to eq(
        'zt 2016-11-01 12:30:09 -01:00 dst:false'
      )
    end

    it 'accepts a duration String' do

      expect(
        EtOrbi::EoTime.make('1h')
      ).to be_between(
        Time.now + 3600 - 1, Time.now + 3600 + 1
      )
    end

    it 'accepts a Numeric' do

      expect(
        EtOrbi::EoTime.make(3600)
      ).to be_between(
        Time.now + 3600 - 1, Time.now + 3600 + 1
      )
    end

    it 'rejects unparseable input' do

      expect {
        EtOrbi::EoTime.make('xxx')
      #}.to raise_error(ArgumentError, 'couldn\'t parse "xxx"')
      }.to raise_error(ArgumentError, 'no time information in "xxx"')
        # straight out of Time.parse()

      expect {
        EtOrbi::EoTime.make(Object.new)
      }.to raise_error(ArgumentError, /\Acannot turn /)
    end
  end

  describe '#to_time' do

    it 'returns a local Time instance, although with a UTC zone' do

      zt = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
      t = zt.to_time

      expect(zt.to_debug_s).to eq('zt 2007-10-31 23:25:00 -08:00 dst:true')

      expect(t.to_i).to eq(1193898300 - 7 * 3600) # /!\

      expect(t.to_debug_s).to eq('t 2007-10-31 23:25:00 +00:00 dst:false')
        # Time instance stuck to UTC...
    end
  end

  describe '#utc' do

    it 'returns an UTC Time instance' do

      zt = EtOrbi::EoTime.new(1193898300, 'America/Los_Angeles')
      ut = zt.utc

      expect(ut.to_i).to eq(1193898300)

      expect(zt.to_debug_s).to eq('zt 2007-10-31 23:25:00 -08:00 dst:true')
      expect(ut.to_debug_s).to eq('t 2007-11-01 06:25:00 +00:00 dst:false')
    end
  end

  describe '#add' do

    it 'adds seconds' do

      zt = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')
      zt.add(111)

      expect(zt.seconds).to eq(1193898300 + 111)
    end

    it 'goes into DST' do

      zt =
        EtOrbi::EoTime.new(
          Time.gm(2015, 3, 8, 9, 59, 59),
          'America/Los_Angeles')

      t0 = zt.dup
      zt.add(1)
      t1 = zt

      st0 = t0.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t0.isdst}"
      st1 = t1.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t1.isdst}"

      expect(t0.to_i).to eq(1425808799)
      expect(t1.to_i).to eq(1425808800)
      expect(st0).to eq('2015/03/08 01:59:59 PST false')
      expect(st1).to eq('2015/03/08 03:00:00 PDT true')
    end

    it 'goes out of DST' do

      zt =
        EtOrbi::EoTime.new(
          ltz('Europe/Berlin', 2014, 10, 26, 01, 59, 59),
          'Europe/Berlin')

      t0 = zt.dup
      zt.add(1)
      t1 = zt.dup
      zt.add(3600)
      t2 = zt.dup
      zt.add(1)
      t3 = zt

      st0 = t0.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t0.isdst}"
      st1 = t1.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t1.isdst}"
      st2 = t2.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t2.isdst}"
      st3 = t3.strftime('%Y/%m/%d %H:%M:%S %Z') + " #{t3.isdst}"

      expect(t0.to_i).to eq(1414281599)
      expect(t1.to_i).to eq(1414285200 - 3600)
      expect(t2.to_i).to eq(1414285200)
      expect(t3.to_i).to eq(1414285201)

      expect(st0).to eq('2014/10/26 01:59:59 CEST true')
      expect(st1).to eq('2014/10/26 02:00:00 CEST true')
      expect(st2).to eq('2014/10/26 02:00:00 CET false')
      expect(st3).to eq('2014/10/26 02:00:01 CET false')

      expect(t1 - t0).to eq(1)
      expect(t2 - t1).to eq(3600)
      expect(t3 - t2).to eq(1)
    end
  end

  describe '#to_f' do

    it 'returns the @seconds' do

      zt = EtOrbi::EoTime.new(1193898300, 'Europe/Paris')

      expect(zt.to_f).to eq(1193898300)
    end
  end

  describe '#strftime' do

    it 'accepts %Z, %z, %:z and %::z' do

      expect(
        EtOrbi::EoTime.new(0, 'Europe/Bratislava') \
          .strftime('%Y-%m-%d %H:%M:%S %Z %z %:z %::z')
      ).to eq(
        '1970-01-01 01:00:00 CET +0100 +01:00 +01:00:00'
      )
    end

    it 'accepts %/Z' do

      expect(
        EtOrbi::EoTime.new(0, 'Europe/Bratislava') \
          .strftime('%Y-%m-%d %H:%M:%S %/Z')
      ).to eq(
        "1970-01-01 01:00:00 Europe/Bratislava"
      )
    end
  end

  describe '#monthdays' do

    def mds(t); EtOrbi::EoTime.new(t.to_f, nil).monthdays; end

    it 'returns the appropriate "0#2"-like string' do

      expect(mds(local(1970, 1, 1))).to eq(%w[ 4#1 4#-5 ])
      expect(mds(local(1970, 1, 7))).to eq(%w[ 3#1 3#-4 ])
      expect(mds(local(1970, 1, 14))).to eq(%w[ 3#2 3#-3 ])

      expect(mds(local(2011, 3, 11))).to eq(%w[ 5#2 5#-3 ])
    end
  end

  describe '.extract_iso8601_zone' do

    def eiz(s); EtOrbi::EoTime.extract_iso8601_zone(s); end

    it 'returns the zone string' do

      expect(eiz '2016-11-01 12:30:09-01').to eq('-01:00')
      expect(eiz '2016-11-01 12:30:09-01:00').to eq('-01:00')
      expect(eiz '2016-11-01 12:30:09 -01').to eq('-01:00')
      expect(eiz '2016-11-01 12:30:09 -01:00').to eq('-01:00')

      expect(eiz '2016-11-01 12:30:09-01:30').to eq('-01:30')
      expect(eiz '2016-11-01 12:30:09 -01:30').to eq('-01:30')
    end

    it 'returns nil when it cannot find a zone' do

      expect(eiz '2016-11-01 12:30:09').to eq(nil)
      expect(eiz '2016-11-01 12:30:09-25').to eq(nil)
      expect(eiz '2016-11-01 12:30:09-25:00').to eq(nil)
    end
  end

  describe '.list_tzones(time)' do

    it 'works in Shanghai' do

      in_zone 'Asia/Shanghai' do

        t = Time.parse('2017-03-18 05:48:11')

        tznames = EtOrbi::EoTime.list_tzones(t).collect(&:name)
#pp tznames

        expect(tznames).to include('Asia/Chongqing')
        expect(tznames).to include('Asia/Shanghai')
        expect(tznames).to include('PRC')

        #Asia/Chongqing Asia/Chungking Asia/Harbin Asia/Macao Asia/Macau
        #Asia/Shanghai Asia/Taipei PRC ROC
      end
    end

    it 'works in New York (winter 2017)' do

      in_zone 'America/New_York' do

        t = Time.parse('2017-01-01 05:48:11')

        tznames = EtOrbi::EoTime.list_tzones(t).collect(&:name)
#pp tznames

        expect(tznames).to include('America/Atikokan')
        expect(tznames).to include('America/New_York')
        expect(tznames).to include('EST')
        expect(tznames).to include('America/Jamaica')

        #America/Atikokan America/Cancun America/Cayman America/Coral_Harbour
        #America/Detroit America/Fort_Wayne America/Indiana/Indianapolis
        #America/Indiana/Marengo America/Indiana/Petersburg
        #America/Indiana/Vevay America/Indiana/Vincennes
        #America/Indiana/Winamac America/Indianapolis America/Iqaluit
        #America/Jamaica America/Kentucky/Louisville
        #America/Kentucky/Monticello America/Louisville America/Montreal
        #America/Nassau America/New_York America/Nipigon America/Panama
        #America/Pangnirtung America/Port-au-Prince America/Thunder_Bay
        #America/Toronto Canada/Eastern EST EST5EDT Jamaica US/East-Indiana
        #US/Eastern US/Michigan
      end
    end

    it 'works in New York (summer 2017)' do

      in_zone 'America/New_York' do

        t = Time.parse('2017-08-01 05:48:11')

        tznames = EtOrbi::EoTime.list_tzones(t).collect(&:name)
#pp tznames

        expect(tznames).not_to include('America/Atikokan')
        expect(tznames).to include('America/New_York')
        expect(tznames).to include('EST5EDT')
        expect(tznames).not_to include('America/Jamaica')

        #America/Detroit America/Fort_Wayne America/Indiana/Indianapolis
        #America/Indiana/Marengo America/Indiana/Petersburg
        #America/Indiana/Vevay America/Indiana/Vincennes
        #America/Indiana/Winamac America/Indianapolis America/Iqaluit
        #America/Kentucky/Louisville
        #America/Kentucky/Monticello America/Louisville America/Montreal
        #America/Nassau America/New_York America/Nipigon
        #America/Pangnirtung America/Port-au-Prince America/Thunder_Bay
        #America/Toronto Canada/Eastern EST5EDT US/East-Indiana
        #US/Eastern US/Michigan
      end
    end
  end

  describe '.determine_tzone(time)' do

    it 'prefers Asia/Shanghai when in Asia/Shanghai' do

      in_zone 'Asia/Shanghai' do

        t = Time.parse('2017-03-18 05:48:11')

        expect(
          EtOrbi::EoTime.determine_tzone(t).name
        ).to eq('Asia/Shanghai')
      end
    end

    it 'prefers America/New_York when in America/New_York (winter 2017)' do

      in_zone 'America/New_York' do

        t = Time.parse('2017-01-01 05:48:11')

        expect(
          EtOrbi::EoTime.determine_tzone(t).name
        ).to eq('America/New_York')
      end
    end

    it 'prefers America/New_York when in America/New_York (summer 2017)' do

      in_zone 'America/New_York' do

        t = Time.parse('2017-08-01 05:48:11')

        expect(
          EtOrbi::EoTime.determine_tzone(t).name
        ).to eq('America/New_York')
      end
    end
  end
end

