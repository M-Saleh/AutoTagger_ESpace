class ResultsController < ApplicationController
  def index
  text=params[:title]+" " +params[:body]
  candidate = PreprocessingStage::CandidatesContainer.new(text)
  @candidates = candidate.get_candidates   
  end
end
