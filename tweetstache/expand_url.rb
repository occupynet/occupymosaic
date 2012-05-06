require 'net/http'

module BarkingIguana
  module ExpandUrl
    def expand_urls!
      ExpandUrl.services.each do |service|
        gsub!(service[:pattern]) { |match|
          ExpandUrl.expand($2, service[:host]) || $1
        }
      end
    end

    def expand_urls
      s = dup
      s.expand_urls!
      s
    end

    def ExpandUrl.services
      [
        { :host => "tinyurl.com", :pattern => %r'(http://tinyurl\.com(/[\w/]+))' },
        { :host => "is.gd", :pattern => %r'(http://is\.gd(/[\w/]+))' },
        { :host => "bit.ly", :pattern => %r'(http://bit\.ly(/[\w/]+))' },
        { :host => "youtu.be", :pattern => %r'(http://youtu\.be(/[\w/]+))'},
        { :host => "dlvr.it", :pattern => %r'(http://dlvr\.it(/[\w/]+))'},
        { :host => "flic.kr", :pattern => %r'(http://flic\.kr(/[\w/]+))'},
        { :host => "n0.gd", :pattern => %r'(http://n0\.gd(/[\w/]+))'},
        { :host => "huff.to", :pattern => %r'(http://huff\.to(/[\w/]+))'},
        { :host => "ow.ly", :pattern => %r'(http://huff\.to(/[\w/]+))'}
        
      ]
    end

    def ExpandUrl.expand(path, host)
      result = ::Net::HTTP.new(host).head(path)
      case result
      when ::Net::HTTPRedirection
        result['Location']
      end
    end
  end
end

class String
  include BarkingIguana::ExpandUrl
end
