#encoding:utf-8
require 'preprocessing_stage/preproc_helper'
module PreprocessingStage::LinkProbability

#Parse XML file
def self.parse_XML_file
  reader = Nokogiri::XML::Reader(File.open(XML_FILE))
end

def self.ignore_page_from_title title
  TITLE_IGNORE.each do |pat|
    break [] if pat.match(title)
  end.empty?
end

def self.ignore_page_from_text text
  TEXT_IGNORE.each do |pat|
    break [] if pat.match(text)
  end.empty?
end
    
def self.get_all_pages &blk
  all, processed = 0, 0
  reader = parse_XML_file
  # for each page in the xml
  reader.each do |page|
    next if page.name != "page"
    next if page.node_type != Nokogiri::XML::Reader::TYPE_ELEMENT
    all +=1
    doc = {}
    # for each node in the page
    page.each do |node|
      break if node.name == "page" && Nokogiri::XML::Reader::TYPE_END_ELEMENT
      break if node.name == "ns" && node.inner_xml.to_i !=0
      break if node.name == "title" && ignore_page_from_title(node.inner_xml)
      next if node.node_type != Nokogiri::XML::Reader::TYPE_ELEMENT

      doc[node.name] = node.inner_xml.strip if ["id", "title"].include?(node.name)

      if node.name == "revision"
        # for each element in the revision
        node.each do |e|
          break if e.name == "revision" && Nokogiri::XML::Reader::TYPE_END_ELEMENT
          break if e.name == "text" && ignore_page_from_text(node.inner_xml)
          next if node.node_type != Nokogiri::XML::Reader::TYPE_ELEMENT
          doc[e.name] = e.inner_xml.strip if e.name == "text"
        end
        break unless doc.has_key? "text"
      # process the page
      processed +=1
      print '.'
      blk.call(doc)
      break
      end
    end
  end
  puts "Pages Stats: All=#{all}, Processed=#{processed}, Skipped=#{all-processed}"
end

def self.calculate_link_occure
lableOccurrence = {} # {[label,title] => #OfOccur} 
get_all_pages do |page|
  lables=extract_anchor_labels_from_text page["text"]
  lables.each do |link|
    params = split_link(link[0])
    if params != nil && params.size >0
      params[0] = Arabic.normalize(params[0])
      params[1] = Arabic.normalize(params[1])
      
      lableOccurrence[params] = lableOccurrence[params] == nil ? 1:lableOccurrence[params]+1
    end
  end
end

return lableOccurrence
end

# input   page body
# output label of links in this page
def self.extract_anchor_labels_from_text body
  lables=body.scan(LINK_PATTERN)
  return lables
end

def self.split_link link
  page_title, anchor_text = link.split('|')
  return nil if page_title.nil? # Empty
  return nil if page_title.include?('#') # never seen but okey
  anchor_text = page_title if anchor_text.nil?

  if anchor_text.empty?
    l = page_title.rindex(/\(.*\)$/)
    r = l != nil && l != 0  ? page_title[l..-1]  : ''
    anchor_text = page_title.gsub(r,'').strip
  end
  a = anchor_text.gsub(/["'\{\}]/,'').strip
  # anchor (egypt) ==> egypt
  a = a[1..-2].strip if /^\(.*\)$/ === a
  p = page_title.gsub(/["']/,'').strip.gsub(' ', '_')
    return nil if a.is_i? || a.is_stopword? || p.is_i? || p.is_stopword?
    return nil if a.length < 3 || p.length < 3
    [a, p]
end

def self.calculate_text_occure labels_array
trie = Trie.new(labels_array)

text_occure={}
get_all_pages do |page|
  text_occure=trie.compute_text_occur(text_occure, page["text"],labels_array)
end

return text_occure
end

def self.save_link_probability_table link,text
  drop_link_prob_temp_table_if_exist
  create_link_prob_temp_table
    
  link.each do |key, val|
  if (text[key[0]] == nil)
    text[key[0]]= 0
  end
  
  ActiveRecord::Base.connection.execute("
  INSERT IGNORE INTO link_prop_tmp(label, page_title, text_occur, link_occur) 
  VALUES (\"#{key[0]}\",\"#{key[1]}\",#{text[key[0]]},#{val});
  ")
  end
end

def self.extract_save_english_translations
puts "extract english translations"

drop_english_translation_table_if_exist
create_english_translation_table

get_all_pages do |doc|
  resp = doc["text"].scan(ENGLISH_FORM_PATTERN)
  en =  (resp.empty? ? '' :  resp[0][0]).gsub('"','\"')
  ActiveRecord::Base.connection.execute("INSERT INTO english_translation (page_id, en_form) 
  VALUES (#{doc["id"]},\"#{en}\");") unless en.empty?
  
  end  
end
end