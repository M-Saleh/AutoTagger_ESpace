require 'preprocessing_stage/preproc_helper'
class SolarPage < ActiveRecord::Base
  attr_accessible :en_form, :incoming, :link_occur, :outgoing, :page_id, :page_title, :page_type, :s_d_title, :text_occur, :links
  
  searchable do # Index title  
    text :page_title
    integer :page_id, :stored => true  # retrive content also not Only it's reference
  end
  
  def isSynonym?
    @page_type ==1
  end
  
  def isDisambiguate?
    @page_type ==2
  end
  
  def self.compute_incoming_links
    all_pages=SolarPage.all
    all_pages.each do |page|
      page.incoming=ActiveRecord::Base.connection.execute("select count(*)
             from pagelinks
             where  pl_namespace = 0 and pl_title='#{page.s_d_title.gsub(' ','_').gsub('\'','\'\'')}' ;")
      page.save             
    end
  end
  
  def self.compute_outgoing_links
    all_pages=SolarPage.all
    all_pages.each do |page|
      # if page.outgoing.nil? || page.outgoing ==0
        results = ActiveRecord::Base.connection.execute("select pl_title
               from pagelinks
               where  pl_namespace = 0 and pl_from=#{page.page_id} ;")
        page.outgoing = results.size
        outgoing_links=""
        results.each do |r| 
            t= ActiveRecord::Base.connection.execute("select page_id
               from page
               where   page_namespace = 0 and page_title=\"#{r[0].gsub("\"","")}\" ;")
            t.each do |d|
               outgoing_links << "#{d[0]},"
            end 
        end
        page.links = outgoing_links
        page.save    
      # end         
    end
  end
  
  
  #----------------------------- SEARCHING---------------------------------------_____
  
  def self.get_matched_tags(text)
    initial_candidates=[]
    # Preparing text to be examined
    text = Arabic.normalize(text) #Remove Stop words and Normalize
    # Obtain initial candidate tags from solr
    raw_tags =  matching(text)
    initial_candidates=raw_tags.uniq!{|mt| mt.page_id}
        
  return initial_candidates
  end
  
  def self.srch(q,page=1) 
    #TODO increase minimum matching after cleaning the text to get relevant tags only
    begin
      SolarPage.search  do
        keywords q, :fields => [:page_title] do 
          minimum_match 1
        end
        #with(:is_disamb,false) 
        paginate :page => page, :per_page => 10000
      end
    rescue
      SolarPage.connection.reconnect!
      SolarPage.search  do
        keywords q, :fields => [:page_title] do 
          minimum_match 1
        end
        #with(:is_disamb,false) 
        paginate :page => page, :per_page => 10000
      end
    end
  end

def self.matching(q)
    results = srch(q,1)
    matching_tags = SolarPage.where(:page_id=>results.hits.collect{|h| h.stored(:page_id)})
    
    return matching_tags
end

  
end
