module CFExec
  class CompanyColorThemesController < ExecController
    helper_method :layout_config

    def show
      @company = Company.find(params[:company_id])

      setup_color_theme
      render_color_theme_example
    end

    def try
      @company = Company.find(params[:company_id])

      setup_color_theme(color_theme_params)

      respond_to do |format|
        format.html { render_color_theme_example }
        format.js
      end
    end

    def update
      @company = Company.find(params[:company_id])

      setup_color_theme(color_theme_params)

      if @color_theme_form.save
        redirect_to exec_company_path(@company)
      else
        render_color_theme_example
      end
    end

    def destroy
      @company = Company.find(params[:company_id])

      @company.update!(primary_brand_color: nil)

      redirect_to exec_company_path(@company)
    end

    private

    def color_theme_params
      params.fetch(:color_theme, {}).permit(:primary_brand_color)
    end

    def setup_color_theme(with_params = nil)
      @current_nav = "nav_item_1"
      @color_theme_form = ColorThemeForm.new(@company)
      @color_theme_form.assign_attributes(with_params) if with_params
    end

    def render_color_theme_example
      render :show, layout: "color_theme_example"
    end

    def layout_config
      @_layout_config ||= begin
        config = LayoutConfig.new_from_company(@company)
        config.primary_brand_color = @color_theme_form.primary_brand_color if @color_theme_form
        config.root_path = "#"
        config
      end
    end

    class ColorThemeForm
      FULL_COLOR_CODE_PATTERN = /\A\#?\h{6}\z/
      SHORT_COLOR_CODE_PATTERN = /\A\#?\h{3}\z/

      include ActiveModel::Model

      attr_reader :company
      attr_accessor :primary_brand_color

      validates :primary_brand_color, format: { allow_blank: true, with: FULL_COLOR_CODE_PATTERN }

      def initialize(company)
        @company = company
        @primary_brand_color = company.primary_brand_color
      end

      def assign_attributes(params = {})
        params.each do |attr, value|
          self.public_send("#{attr}=", value)
        end
      end

      def primary_brand_color=(value)
        @primary_brand_color =
          if value
            if FULL_COLOR_CODE_PATTERN.match(value.strip)
              prepend_with_pound_sign(value.strip)
            elsif SHORT_COLOR_CODE_PATTERN.match(value.strip)
              prepend_with_pound_sign(expand_short_color_code(value.strip))
            else
              value.strip
            end
          end
      end

      def save
        return false if invalid?

        company.update!(primary_brand_color: primary_brand_color.to_s.downcase.presence)
      end

      private

      def expand_short_color_code(value)
        if value[0] == "#"
          "##{value[1]}#{value[1]}#{value[2]}#{value[2]}#{value[3]}#{value[3]}"
        else
          "#{value[0]}#{value[0]}#{value[1]}#{value[1]}#{value[2]}#{value[2]}"
        end
      end

      def prepend_with_pound_sign(value)
        value[0] == "#" ? value : "##{value}"
      end
    end
  end
end
