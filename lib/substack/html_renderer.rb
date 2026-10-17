module Substack
  # Renders the ProseMirror nodes from HtmlConverter back to plain HTML that
  # pastes cleanly into Substack's editor (the fallback when the API fails).
  class HtmlRenderer
    include ERB::Util

    MARK_TAGS = { "strong" => "strong", "em" => "em", "code" => "code", "strikethrough" => "s" }.freeze

    def render(nodes)
      nodes.map { |node| render_node(node) }.join("\n")
    end

    private

    def render_node(node)
      case node[:type]
      when "paragraph" then "<p>#{render_inlines(node[:content])}</p>"
      when "heading" then "<h#{node[:attrs][:level]}>#{render_inlines(node[:content])}</h#{node[:attrs][:level]}>"
      when "bullet_list" then "<ul>#{render(node[:content])}</ul>"
      when "ordered_list" then "<ol>#{render(node[:content])}</ol>"
      when "list_item" then "<li>#{render(node[:content])}</li>"
      when "blockquote" then "<blockquote>#{render(node[:content])}</blockquote>"
      when "horizontal_rule" then "<hr>"
      when "captionedImage"
        attrs = node[:content].first[:attrs]
        %(<img src="#{h attrs[:src]}" alt="#{h attrs[:alt]}">)
      when "youtube2"
        url = "https://www.youtube.com/watch?v=#{node[:attrs][:videoId]}"
        %(<p><a href="#{h url}">#{h url}</a></p>)
      else ""
      end
    end

    def render_inlines(inlines)
      inlines.map do |node|
        next "<br>" if node[:type] == "hard_break"

        (node[:marks] || []).reverse.reduce(h(node[:text])) do |html, mark|
          if mark[:type] == "link"
            %(<a href="#{h mark[:attrs][:href]}">#{html}</a>)
          else
            tag = MARK_TAGS.fetch(mark[:type])
            "<#{tag}>#{html}</#{tag}>"
          end
        end
      end.join
    end
  end
end
