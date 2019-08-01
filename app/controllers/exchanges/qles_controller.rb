# frozen_string_literal: true

class Exchanges::QlesController < ApplicationController
  before_action :set_qle_and_attributes, only: [:deactivation_form, :edit, :question_flow]
  before_action :set_new_qle_and_questions, only: [:new]
  before_action :set_qles_to_manage, only: [:manage]
  before_action :set_sortable_qles, only: [:sorting_order]
  # TODO: Determine which need the Pundit before_action
  before_action :can_add_custom_qle?, only: [:manage_qle]
  skip_before_action :verify_authenticity_token, only: [:deactivate, :create, :update]

  def manage; end
  
  def manage_qle
    attrs = { market_kind: params.dig(:market_kind) }
    if params[:manage_qle_action] == 'new_qle'
      redirect_to new_exchanges_qle_path(attrs)
    elsif params[:manage_qle_action] == 'modify_qle'
      @qle = QualifyingLifeEventKind.find(params[:id])
      redirect_to edit_exchanges_qle_path(@qle, attrs)
    elsif params[:manage_qle_action] == 'deactivate_qle'
      @qle = QualifyingLifeEventKind.find(params[:id])
      redirect_to deactivation_form_exchanges_qle_path(@qle, attrs)
    end
  end

  def question_flow
    attrs = { market_kind: params.dig(:market_kind) }
    redirect_to question_flow_exchanges_qle_path(@qle, attrs)
  end

  def deactivation_form; end

  def deactivate
    result = Admin::QleKinds::DeactivateService.call(
      current_user,
      params.require("data").permit!.to_hash
    )
    if result.success?
      flash[:notice] = "Successfully deactivated Qualifying Life Event Kind."
    else
      flash[:error] = "Unable to deactivate Qualifying Life Event Kind."
    end
    respond_to do |format|
      format.json { head :no_content, :location => manage_exchanges_qles_path }
    end
  end

  def edit
  end

  def update
    binding.pry
    result = Admin::QleKinds::UpdateService.call(current_user, params.require("data").permit!.to_hash)
    if result.success?
      flash[:notice] = "Successfully updated Qualifying Life Event Kind."
    else
      flash[:error] = "Unable to update Qualifying Life Event Kind."
    end
    render json: {next_url: manage_exchanges_qles_path}
  end

  def sorting_order; end

  def new; end

  def create
    result = Admin::QleKinds::CreateService.call(current_user, params.require("data").permit!.to_hash)
    if result.success?
      flash[:notice] = "Successfully created Qualifying Life Event Kind."
      respond_to do |format|
        format.json { render json: { next_url: manage_exchanges_qles_path } }
      end
    else
      flash[:error] = "Unable to create Qualifying Life Event Kind."
      respond_to do |format|
        format.json { render json: { next_url: manage_exchanges_qles_path } }
      end
    end
  end

  private

  def can_add_custom_qle?
    redirect_to(root_path, :flash => { :error => "Access not allowed" }) unless authorize(HbxProfile, :can_add_custom_qle?)
  end

  def set_sortable_qles
    @qle = QualifyingLifeEventKind.all
  end

  def set_qles_to_manage
    # TODO: Fix these scopes, probably hide them behind a JSON serializer
    # TODO: Consider adding a blank option, and then assure in the qle_kind_wizard
    # that the submit button doesn't work unless a option with a value is selected.
    @editable_qles = QualifyingLifeEventKind.editable
    @deactivatable_qles = QualifyingLifeEventKind.not_set_for_deactivation
  end

  def set_new_qle_and_questions
    @qle = QualifyingLifeEventKind.new
    @qle.custom_qle_questions.build
  end

  def set_qle_and_attributes
    @qle = QualifyingLifeEventKind.find(params[:id])
    @qle_form_attributes = @qle.attributes
  end

  def permitted_params
    params.permit!.to_h
  end
end
