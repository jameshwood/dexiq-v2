# frozen_string_literal: true

module Analysis
  # Fast heuristic-based scoring for token lists
  # No AI required - uses rules-based analysis
  class TokenListHeuristicService
    def initialize(tokens_data)
      @tokens_data = tokens_data # Array of { tokenName, price, volume, change5m, change1h, change6h, change24h, liquidity }
    end

    def analyze
      @tokens_data.map do |token_data|
        score = calculate_score(token_data)
        risk = assess_risk(token_data)
        recommendation = generate_recommendation(score, risk)
        sentiment = determine_sentiment(token_data)

        {
          tokenName: token_data[:tokenName],
          score: score,
          risk: risk,
          recommendation: recommendation,
          sentiment: sentiment,
          emoji: emoji_for_sentiment(sentiment)
        }
      end
    end

    private

    def calculate_score(data)
      score = 50 # Base score

      # Volume scoring (0-20 points)
      volume = data[:volume].to_f
      score += 20 if volume > 1_000_000
      score += 15 if volume.between?(500_000, 1_000_000)
      score += 10 if volume.between?(100_000, 500_000)
      score += 5 if volume.between?(10_000, 100_000)

      # Liquidity scoring (0-20 points)
      liquidity = data[:liquidity].to_f
      score += 20 if liquidity > 1_000_000
      score += 15 if liquidity.between?(500_000, 1_000_000)
      score += 10 if liquidity.between?(100_000, 500_000)
      score += 5 if liquidity.between?(10_000, 100_000)

      # Price action scoring (0-20 points)
      change_24h = data[:change24h].to_f
      score += 20 if change_24h > 50
      score += 15 if change_24h.between?(20, 50)
      score += 10 if change_24h.between?(0, 20)
      score -= 10 if change_24h < -20

      # Recent momentum (0-20 points)
      change_5m = data[:change5m].to_f
      change_1h = data[:change1h].to_f
      avg_short_term = (change_5m + change_1h) / 2
      score += 20 if avg_short_term > 10
      score += 10 if avg_short_term.between?(0, 10)
      score -= 10 if avg_short_term < -10

      # Cap score between 0 and 100
      [[score, 0].max, 100].min
    end

    def assess_risk(data)
      risk_factors = []

      # Low liquidity risk
      liquidity = data[:liquidity].to_f
      risk_factors << "low_liquidity" if liquidity < 50_000

      # High volatility risk
      change_5m = data[:change5m].to_f.abs
      change_1h = data[:change1h].to_f.abs
      risk_factors << "high_volatility" if change_5m > 20 || change_1h > 30

      # Dump risk (sharp decline)
      change_24h = data[:change24h].to_f
      risk_factors << "sharp_decline" if change_24h < -30

      return "high" if risk_factors.length >= 2
      return "medium" if risk_factors.length == 1
      "low"
    end

    def generate_recommendation(score, risk)
      return "avoid" if risk == "high" || score < 30
      return "watch" if score.between?(30, 60) || risk == "medium"
      return "consider" if score.between?(60, 80)
      "strong_buy"
    end

    def determine_sentiment(data)
      change_24h = data[:change24h].to_f

      return "very_bullish" if change_24h > 50
      return "bullish" if change_24h.between?(10, 50)
      return "neutral" if change_24h.between?(-10, 10)
      return "bearish" if change_24h.between?(-50, -10)
      "very_bearish"
    end

    def emoji_for_sentiment(sentiment)
      case sentiment
      when "very_bullish" then "🚀"
      when "bullish" then "📈"
      when "neutral" then "➡️"
      when "bearish" then "📉"
      when "very_bearish" then "💀"
      else "❓"
      end
    end
  end
end
