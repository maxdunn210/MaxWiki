require 'net/http'

class Geocode
  
  attr_accessor :address, :found, :city, :alternatives
  
  X = 0
  Y = 1
  
  def initialize(addr, force = false)
    site = "http://rpc.geocoder.us/service/csv?address="
    @address = addr
    
    # This lookup can take a really long time, so in test mode just fake it
    if not force && RAILS_ENV == 'test'
      @ret = test_addr(addr)
    else
      @ret = Net::HTTP.get URI.parse(site+URI.escape(addr))
    end
    if (@ret =~ /2: .*sorry/) != nil
      @found = false
    else
      @found = true
    end
    @alternative = @ret.split('\n')
    @parts = @alternative[0].split(',')
    @longitude = @parts[0]
    @latitude = @parts[1]
    @city = @parts[3]
  end
  
  def test_addr(addr)  
    if ['123 Mickey Mouse'].find {|str| addr.include?(str)}
      "2: couldn't find this address! sorry"
    elsif addr.include?('95014') && !['20202 Northcove SQ,', '20073 Northcrest Sq'].find {|str| addr.include?(str)}
      '37.318142,-121.998041,18671 Pring Ct,Cupertino,CA,95014'
    else
      '37.297942,-122.008835,5920 Royal Ann Dr,San Jose,CA,95129'      
    end
  end
  
  def show_all
    print @addr, "\n"
    print @ret, "\n"
  end
  
  def longitude
    @parts[X].to_f
  end
  
  def latitude
    @parts[Y].to_f
  end
  
  #~ def slope(i,j)
  #~ (j[Y] - i[Y])/(j[X] - i[X])
  #~ end
  
  #~ def intercept(i,j)
  #~ i[Y] - (j[Y] - i[Y])/(j[X] - i[X]) * i[X]
  #~ end
  
  #~ def left(i,j)
  #~ latitude < slope(i,j) * longitude + intercept(i,j)
  #~ end
  
  #~ def right(i,j)
  #~ latitude > slope(i,j) * longitude + intercept(i,j)
  #~ end
  
  
  
  # The following code is by Randolph Franklin, it returns 1 for interior points and 0 for exterior points.
  # It is a simple (to implement) algorithm, described in "Determining if a point lies on the interior of a polygon", 
  # by Paul Bourke, November 1987 (http://astronomy.swin.edu.au/~pbourke/geometry/insidepoly/)
  # The original algorithm was in C (of course).
  #~ int pnpoly(int npol, float *xp, float *yp, float x, float y)
  #~ {
  #~ int i, j, c = 0;
  #~ for (i = 0, j = npol-1; i < npol; j = i++) {
  #~ if ((((yp[i] <= y) && (y < yp[j])) ||
  #~ ((yp[j] <= y) && (y < yp[i]))) &&
  #~ (x < (xp[j] - xp[i]) * (y - yp[i]) / (yp[j] - yp[i]) + xp[i]))
  #~ c = !c;
  #~ }
  #~ return c;
  #~ }
  
  # verts is a list of vertices
  def pnpoly(verts, x, y)
    v2 = verts[-1]
    c = false
    verts.each {|v1|
      if ((((v1[1] <= y) && (y < v2[1])) ||
       ((v2[1] <= y) && (y < v1[1]))) &&
       (x < (v2[0] - v1[0]) * (y - v1[1]) / (v2[1] - v1[1]) + v1[0]))
        c = !c
      end
      v2 = v1
    }
    c
  end
  
  def waiver_required
    verts = [[37.3344, -122.0322], # (de Anza & 280)
    [ 37.3343, -122.0217], #  (280 bend)
    [ 37.3208, -121.9955], # (280 & Lawrence)
    [ 37.3090, -121.9963], #, (Bolinger & Lawrence)
    [37.3104, -122.0077], # (Bolinger & Tantau [concave bend])
    [37.3095, -122.0214],#  (Bolinger & ?? [convex bend])
    [37.3124, -122.0322] #  (Bolinger & de Anza)
    ]
    not pnpoly(verts,@longitude.to_f,@latitude.to_f)
  end
  
  
end


