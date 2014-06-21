class FullNameSplitter

  PREFIXES = %w(de da la du del dei vda. dello della degli delle van von der den heer ten ter vande vanden vander voor ver aan mc mac ben ibn bint al).freeze
  HONORIFICS = %w(mr mrs miss ms dr capt ofc rev prof sir cr hon).freeze

  def initialize(full_name, honorific=false)
    full_name ||= ''
    @full_name  = full_name.to_s.strip.gsub(/\s+/, ' ')
    @honorific = [] if honorific
    @first_name = []
    @last_name  = []
    split!
  end

  def split!
    # Reset these
    @first_name = []
    @last_name  = []
    @honorific  = [] if honorific?

    # deals with comma, eg. Smith, John => John Smith
    tokens = @full_name.split(',')
    if tokens.size == 2
      @full_name = (tokens[1] + ' ' + tokens[0]).lstrip
    end

    @units = @full_name.split(/\s+/)
    while @unit = @units.shift do
      if honorific?
        @honorific << @unit
      elsif prefix? or with_apostrophe? or (first_name? and last_unit? and not initial?) or (has_honorific? and last_unit? and not first_name?)
        @last_name << @unit and break
      else
        @first_name << @unit
      end
    end
    @last_name += @units

    adjust_exceptions!
  end


  def split_with_honorific(name)
    split(name, true)
  end

  def split(name, honorific=false)
  end

  def honorific
    @honorific.nil? || @honorific.empty? ? nil : @honorific[0].gsub(/[^\w]/, '')
  end

  def first_name
    @first_name.empty? ? nil : @first_name.join(' ')
  end

  def last_name
    @last_name.empty? ? nil : @last_name.join(' ')
  end

  private

  def honorific?
    !@honorific.nil? && HONORIFICS.include?(@unit.downcase.gsub(/[^\w]/, '')) && @honorific.empty? && @first_name.empty? && @last_name.empty?
  end

  def has_honorific?
    not @honorific.nil? and not @honorific.empty?
  end

  def prefix?
    PREFIXES.include?(@unit.downcase)
  end

  # M or W.
  def initial?
    @unit =~ /^\w\.?$/
  end

  # O'Connor, d'Artagnan match
  # Noda' doesn't match
  def with_apostrophe?
    @unit =~ /\w{1}'\w+/
  end

  def last_unit?
    @units.empty?
  end

  def first_name?
    not @first_name.empty?
  end

  def adjust_exceptions!
    return if @first_name.size <= 1

    # Adjusting exceptions like
    # "Ludwig Mies van der Rohe"      => ["Ludwig",         "Mies van der Rohe"   ]
    # "Juan Martín de la Cruz Gómez"  => ["Juan Martín",    "de la Cruz Gómez"    ]
    # "Javier Reyes de la Barrera"    => ["Javier",         "Reyes de la Barrera" ]
    # Rosa María Pérez Martínez Vda. de la Cruz
    #                                 => ["Rosa María",     "Pérez Martínez Vda. de la Cruz"]
    if last_name =~ /^(van der|(vda\. )?de la \w+$)/i
      loop do
        @last_name.unshift @first_name.pop
        break if @first_name.size <= 2
      end
    end
  end
end
