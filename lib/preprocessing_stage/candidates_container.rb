#encoding: utf-8
require 'preprocessing_stage/arabic_normalizer'

class PreprocessingStage::CandidatesContainer
  include ScoreFunction
  attr_accessor :tags , :article ,  :candidates
  
  def initialize(article)
  @article = Arabic.normalize(article)
  @tags = SolarPage.get_matched_tags(article)|| []
  @candidates = []
  @tags.each do |tag|
    c = PreprocessingStage::Candidate.new(tag)
    @candidates<<c
  end 
    calculate_score_function_for_tags
    return @candidates
  end

  def calculate_score_function_for_tags
    @candidates.each do |c|
      c.calculate_scoreFunction(@article,@candidates,SCORE_FUNCATION)
    end 
  end
  
    def get_candidates
      @candidates.each do |c|
        puts "#{c.title} #{c.score}" 
      end

      return @candidates 
  end
end