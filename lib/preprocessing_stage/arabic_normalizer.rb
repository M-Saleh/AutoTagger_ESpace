# encoding: UTF-8
require 'singleton'
#modified version of ArabicNormalizer from http://arabtechies.sourceforge.net/project/normalization_ruby
class PreprocessingStage::ArabicNormalizer
  include Singleton
  @stopwords = nil 
  attr_reader :stopwords
  def initialize
    # Define language normalization rules
    @tashkeel = { :fatha=>'َ', :damma=>'ُ', :kasra=>'ِ', :sukun=>'ْ', :shadda=>'ّ', :fathatan=>'ً', :damatan=>'ٌ', :kasratan=>'ٍ' }
    @tatweel = { :tatweel=>'ـ' }
    #@hamza = { :wawhamza=>'ؤ', :yehhamza=>'ئ' }
    @alef = { :madda=>'آ', :hamzaabove=>'أ', :hamzabelow=>'إ' }
    @lamalef= { :lamalef=>'ﻻ', :hamzabove=>'ﻷ'  , :hamzabelow=>'ﻹ', :madda=>'ﻵ' }
    @yeh = { :yeh=>'ى' }
    @heh = { :heh=>'ه', :teh => 'ة'}
    @norm_all = @tashkeel

    # Build regexs for the above rules
    @tashkeel_reg = { :reg=>build_regex(@tashkeel), :replacement=>'' }
    @tatweel_reg = { :reg=>build_regex(@tatweel), :replacement=>'' }
    #@hamza_reg = { :reg=>build_regex(@hamza), :replacement=>'ء' }
    @alef_reg = { :reg=>build_regex(@alef), :replacement=>'ا' }
    @lamalef_reg = { :reg=>build_regex(@lamalef), :replacement=>"لا"}
    @yeh_reg = { :reg=>build_regex(@yeh), :replacement=>'ي' }
    @heh_reg = { :reg=>build_regex(@heh), :replacement=>'ه' }
    # Build a hash representing the available options for normalization
    @options={:norm_all=>[:tashkeel, :tatweel, :alef, :lamalef, :yeh, :heh],
      :tashkeel=>@tashkeel_reg, :tatweel=>@tatweel_reg, :alef=>@alef_reg,
      :lamalef=>@lamalef_reg, :yeh=>@yeh_reg, :heh=>@heh_reg}
    @stopwords = load_stopWords
  end
  
  def load_stopWords
    file = File.new("#{::Rails.root}/resources/new_stop_words.txt", "r")
    stopwords ={}
    while (line = file.gets)
      line = line.chop
      stopwords[line] = true
    end #end while 
    return stopwords
  end
  
  def removeStopWords (input_txt)
    array = input_txt.split(" ")
    tokens = []
    array.each do |word|
      if @stopwords[word].nil? 
          tokens << word
      end
    end
    return tokens.join(" ")
  end
  
  def normalize(input, options=@options[:norm_all])
    input = removeStopWords(input)
    (options = options.is_a?(Array) ? options : [options]).each do |option|
      input=input.gsub(@options[option][:reg], @options[option][:replacement] )
    end
    return input
  end

  def normalize_only(input, options=@options[:norm_all])
    (options = options.is_a?(Array) ? options : [options]).each do |option|
      input=input.gsub(@options[option][:reg], @options[option][:replacement] )
    end
    return input
  end
  protected

  def build_regex(hash)
    return Regexp.compile(/[#{hash.values.join}]/)
  end
end

Arabic = PreprocessingStage::ArabicNormalizer.instance

class String
  def is_i?
    !!(self =~ /^[-+]?[0-9]+$/)
  end
  def is_stopword?
    Arabic.stopwords.include?(self)
  end
end