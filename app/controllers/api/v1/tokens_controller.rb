# frozen_string_literal: true

module Api
  module V1
    # Tokens API Controller
    # Handles token creation, analysis, purchases, and chat
    class TokensController < BaseController
      before_action :set_token, only: [:show, :status, :analyse_pair, :purchases, :create_purchase, :chat_with_ai]

      # POST /api/v1/tokens
      # Create or find a token, trigger data fetch
      def create
        @token = Token.find_or_create_by_pool!(
          chain_id: token_params[:chain_id],
          pool_address: token_params[:pool_address],
          user: current_user,
          symbol: token_params[:symbol],
          quote_symbol: token_params[:quote_symbol],
          token_url: token_params[:token_url]
        )

        # Enqueue background job to fetch data (orchestrates all data fetching)
        Tokens::FetchDataJob.perform_later(@token.id)

        render_success(
          token_id: @token.id,
          message: "Token created/found. Data fetch enqueued."
        )
      rescue ActiveRecord::RecordInvalid => e
        render_error("Failed to create token", errors: e.record.errors.full_messages)
      end

      # GET /api/v1/tokens/:id
      # Get token details with all snapshots
      def show
        presenter = Presenters::TokenPresenter.new(@token, include_snapshots: true)
        render_success(token: presenter.as_json)
      end

      # GET /api/v1/tokens/:id/status
      # Get data readiness status
      def status
        readiness_service = Tokens::DataReadinessService.new(@token)
        render_success(readiness_service.status)
      end

      # POST /api/v1/tokens/:id/analyse_pair
      # Deep AI analysis for single pair
      def analyse_pair
        analysis_service = Analysis::TokenPairAnalysisService.new(
          @token,
          symbol: analysis_params[:symbol],
          quote_symbol: analysis_params[:quote_symbol],
          purchase_price: analysis_params[:purchase_price]
        )

        result = analysis_service.analyze
        presenter = Presenters::AnalysisPresenter.new(result)

        render_success(data: presenter.as_json)
      rescue => e
        Rails.logger.error("Analysis error: #{e.class} - #{e.message}")
        render_error("Analysis failed: #{e.message}", status: :internal_server_error)
      end

      # POST /api/v1/analyse_tokens
      # Analyze a list of tokens (heuristic or AI)
      def analyse_tokens
        tokens_data = analyse_tokens_params[:tokens]

        analysis_service = Analysis::TokenListHeuristicService.new(tokens_data)
        result = analysis_service.analyze

        render_success(data: result)
      rescue => e
        Rails.logger.error("Token list analysis error: #{e.class} - #{e.message}")
        render_error("Analysis failed: #{e.message}", status: :internal_server_error)
      end

      # GET /api/v1/tokens/:id/purchases
      # Get purchase history and P&L
      def purchases
        presenter = Presenters::PurchasePresenter.new(@token, current_user)
        render_success(presenter.as_json)
      end

      # POST /api/v1/tokens/:id/purchases
      # Log a buy or sell transaction
      def create_purchase
        purchase = @token.purchase_logs.build(
          user: current_user,
          transaction_type: purchase_params[:transaction_type],
          amount: purchase_params[:amount],
          price_per_token: purchase_params[:price_per_token],
          transaction_hash: purchase_params[:transaction_hash],
          notes: purchase_params[:notes]
        )

        if purchase.save
          presenter = Presenters::PurchasePresenter.new(@token, current_user)
          render_success(
            purchase: purchase.as_json,
            current_position: presenter.send(:current_position_json),
            message: "Transaction logged successfully"
          )
        else
          render_error("Failed to log transaction", errors: purchase.errors.full_messages)
        end
      end

      # POST /api/v1/chat_with_ai
      # AI chat about a token
      def chat_with_ai
        # TODO: Implement OpenAI chat with context
        # For now, return a placeholder

        session_id = chat_params[:session_id] || SecureRandom.uuid
        prompt = chat_params[:prompt]

        # Save interaction
        interaction = @token.ai_chat_interactions.create!(
          user: current_user,
          session_id: session_id,
          prompt: prompt,
          reply: "AI chat response placeholder. TODO: Implement OpenAI integration."
        )

        render_success(
          reply: interaction.reply,
          session_id: session_id
        )
      rescue => e
        Rails.logger.error("Chat error: #{e.class} - #{e.message}")
        render_error("Chat failed: #{e.message}", status: :internal_server_error)
      end

      private

      def set_token
        @token = current_user.tokens.find(params[:id])
      end

      def token_params
        params.require(:token).permit(:chain_id, :pool_address, :symbol, :quote_symbol, :token_url)
      rescue ActionController::ParameterMissing
        # Allow direct params if not nested
        params.permit(:chain_id, :pool_address, :symbol, :quote_symbol, :token_url)
      end

      def analysis_params
        params.permit(:symbol, :quote_symbol, :purchase_price)
      end

      def analyse_tokens_params
        params.permit(tokens: [:tokenName, :price, :volume, :change5m, :change1h, :change6h, :change24h, :liquidity])
      end

      def purchase_params
        params.require(:purchase).permit(:transaction_type, :amount, :price_per_token, :transaction_hash, :notes)
      end

      def chat_params
        params.permit(:prompt, :session_id, :pairData, :analysis, :session_start_time)
      end
    end
  end
end
