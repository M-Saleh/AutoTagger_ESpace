class PreprocessingStage::Candidate

      # attr_accessor :article, :tag
      attr_reader :id
      # @return [String] document title => standard tag form
      attr_reader :title
      # @return [Integer] number of incoming links 
      attr_reader :incoming
      # @return [Integer] number of outgoing links
      attr_reader :outgoing
      # @return [Array<Integer>] array of outgoing links
      attr_reader :links
      # @return [Integer] number of links to other candidate tags
      attr_reader :to_other_tags
      # @return [Float] score
      attr_reader :score
      # @return [Float] position ratio = index of first word divided by number of words in query
      attr_reader :pos
      # @return [Integer] frequency
      attr_reader :freq
      # @return [Array<String>] array of matched titles => other tag forms [synoyms, disambiguator]
      attr_reader :matched_titles
      # @return [String] english translation
      attr_reader :en
      # @return [Integer] link occurrence
      attr_reader :link_occur
      # @return [Integer] text occurrence
      attr_reader :text_occur
      # @return [Float] link probability 
      attr_reader :link_prop
  
  def initialize( tag)
      @id = tag.page_id
      @matched_titles = tag.page_title
      @title = tag.s_d_title
      @incoming = tag.incoming || 0
      @outgoing = tag.outgoing || 0
      @en = tag.en_form || ""
      @link_occur = tag.link_occur || 0
      @text_occur = tag.text_occur || 0
      @link_prop  =  @link_prop = @link_occur == 0 && @text_occur == 0 ? -1 : @text_occur == 0 ? 1 :  @link_occur / @text_occur.to_f 
      @pos =  1.0     # initial value 
      @freq = 1.0       # initial value 
      @to_other_tags=0   # initial value 
      @links = tag.links.split(",") || []
  end

  
    def  calculate_position(article)
      quey_words = article.split(" ")
      index = quey_words.index((@matched_titles.split(" ")).first)
      return 1-((index||1)/quey_words.size.to_f)
    end 
  
    def  calculate_freq article   
      return  (" #{article} ").scan(" #{@matched_titles} ").length
    end 
    
    def  get_links
      results =  ActiveRecord::Base.connection.execute("select outlinks from page_outlinks where page_id =#{@id} ;") 
      results.each do |r|
        return r[0].split(",")
      end
    end 
 
    def compute_links_to_other_tags docs
      docs.each do |d|
        if (@links.include?"#{d.id}")
          @to_other_tags +=1
        end
      end
    end
    
    def calculate_scoreFunction(article , candidates_arr, scoringfunc)
      puts article
        @pos = calculate_position(article)
        @freq = calculate_freq article
        @to_other_tags = compute_links_to_other_tags candidates_arr
        
        l = @matched_titles.length.to_f
        n = @matched_titles.scan(" ").size.to_f
        w = article.split(" ").length.to_f+1
        f = @freq.to_f
        p = @pos
        t = @to_other_tags.size.to_f
        i = @incoming.to_f
        o = @outgoing.to_f  
        lp= @link_prop
        # rc = calculate_scoreFunction_cos @matched_titles, aritcle
        # rj = calculate_scoreFunction_jac @matched_titles, aritcle
        rc = relatedness_measure_cosine_similarity candidates_arr
        rj = relatedness_measure_jaccard_index candidates_arr
        @score = eval(scoringfunc) 
        @score = 0 unless @score.finite?
    end 
    
    def relatedness_measure_cosine_similarity chosen_tags
        return 0 if chosen_tags.empty?
        links = chosen_tags.map{|tag| tag.links}.reduce(:+)
        return 0 if links.nil?
        return 0 if links.empty? || @links.empty?
        intersection = (@links & links).length.to_f
        a = Math.sqrt(1.0 / @links.length)
        b = Math.sqrt(1.0 / links.length)
        a * b * intersection
      end 
         
     def relatedness_measure_jaccard_index chosen_tags
        return 0 if chosen_tags.empty?
        r_measure = 0
        chosen_tags.each do |tag|
          intersection = (@links & tag.links).length.to_f
          union = (@links | tag.links).length
          r_measure += union.zero? ? 0 : (intersection/union)
        end
        r_measure = r_measure/chosen_tags.length
        r_measure
      end
      
      def log n
        Math.log(n)
      end 
  
end