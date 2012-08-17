class ResultsController < ApplicationController
  def index
  text=params[:title]+" " +params[:body]
  candidate = PreprocessingStage::CandidatesContainer.new(text)
  @candidates = candidate.get_candidates
#   use this variable in result#index to view the results
  end

  def create
    index
  end  
end
