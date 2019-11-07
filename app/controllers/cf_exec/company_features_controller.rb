module CFExec
  class CompanyFeaturesController < ExecController
    def create
      @company = Company.find(params[:company_id])

      feature_flag = FeatureFlag.new
      feature_flag.assign_attributes(params.require(:feature).permit(:identifier))
      feature_flag.resource = @company
      feature_flag.save!

      respond_to do |format|
        format.html { redirect_to exec_company_path(@company) }
        format.js {
          @feature_flag_identifier = feature_flag.identifier
          @updated_feature_flag = feature_flag
          render :toggle
        }
      end
    end

    def destroy
      @company = Company.find(params[:company_id])

      FeatureFlag.revoke(resource: @company, identifier: params[:id])

      respond_to do |format|
        format.html { redirect_to exec_company_path(@company) }
        format.js {
          @feature_flag_identifier = params[:id]
          @updated_feature_flag = FeatureFlag.new(identifier: params[:id])
          render :toggle
        }
      end
    end
  end
end
