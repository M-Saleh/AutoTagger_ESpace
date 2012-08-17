# encoding: UTF-8
require 'preprocessing_stage/preproc_helper'

#This class used to calculate number of occurrence for each title (anchore text) as a text not as a link
#initialize with array contain all titles
#call compute_text_occur function with text
class Trie 
    WORD_PATTERN = /[\p{Word}\(\)\-'\.\/،]+/
    attr_reader :text_occur
    attr_reader :trie

    def initialize arr
      @trie = {}
      @text_occur = {}
      if arr.is_a? Hash  #if call by hash update the trie with it,else build it.
        @trie.update(arr)
        return
      end
      a = arr.map{|e| Arabic.normalize(e).split(' ').map{|m| m.strip}}
      #puts "Add #{a.length} Labels"
      
      build_trie a
      
    end
    
    # compute the text occurrences of trie elements in the processed text
    # @param [String] text is the text to be processed
    # @param [true, false] count_all_the_occur if true count the number of occurrences for each phrase
    # @return [Hash<String, Integer>] text occurence for trie labels inside this text
    # @example without counting the occurrences
    #     trie = AutoTagger::Trie.new(["foo", "foo bar", "bar", "bar foo"])
    #     p trie.trie
    #     #=> {"foo" => { :x => 1, "bar" => {:x => 1} }, "bar" => { :x => 1, "foo" => {:x => 1} } } 
    #     trie.compute_text_occur("foo bar this text foo and bar")
    #     p trie.text_occur
    #     #=> {"foo"=>1, "foo bar"=>1, "bar"=>1}
    # @example with counting the occurrences
    #     trie = AutoTagger::Trie.new(["foo", "foo bar", "bar", "bar foo"])
    #     p trie.trie
    #     #=> {"foo" => { :x => 1, "bar" => {:x => 1} }, "bar" => { :x => 1, "foo" => {:x => 1} } } 
    #     trie.compute_text_occur("foo bar this text foo and bar", true)
    #     p trie.text_occur
    #     #=> {"foo"=>2, "foo bar"=>1, "bar"=>2}
    
    def compute_text_occur text_occur_accum, text ,labels, count_all_the_occur=false
      words = Arabic.normalize(text).scan(WORD_PATTERN)
      words.each_with_index do |word , index|
        compute_text_occur_for_word word, index, words, text_occur_accum
      end
      text_occur_accum.each do |k, val| 
        @text_occur[k] ||= 0
        @text_occur[k] += count_all_the_occur ? val : 1
      end
      text_occur_accum
    end
    
    private
    def build_trie arr
      arr.each do |a|
        next if (a == nil || a.size ==0)
        #puts "A=#{a}"
        node = @trie
        node = node[a[0]] ||= {}
        a[1..-1].each do |e|
          node = node[e] ||={}
        end
        node[:x] = 1
      end
    end
    
    def compute_text_occur_for_word word, i, words, accum
      phrases, index = [[word]], i+1
      wt = @trie[word]
      return unless wt
      if wt.has_key? :x
        accum[word] ||= 0
        accum[word] += 1
      end
      phrases = loop do
        word = words[index]
        if wt.has_key? word
          phrases.last << word
          phrases.push(phrases.last.dup) if wt[word].has_key?(:x)
        else
          break wt.has_key?(:x) ? phrases.map{|phrase| phrase.length >1 ? phrase.join(' ') : nil} : []
        end
        wt = wt[word]
        index += 1
      end
      
      phrases.uniq.compact.each do |phrase|
          accum[phrase] ||=0
          accum[phrase] += 1
      end
      
    end
  end