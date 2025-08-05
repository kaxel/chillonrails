#encoding: UTF-8
xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "CHILLFILTR® - Latest Posts"
    xml.atom :link, "href" => url_for(controller: 'posts', action: 'feed', format: :rss, only_path: false), "rel" => "self", "type" => "application/rss+xml"
    xml.link root_url
    xml.description "CHILLFILTR® is a multifaceted platform dedicated to amplifying independent voices in both music and literature."
    xml.language "en-us"
    xml.lastBuildDate @posts.first&.updated_at&.to_formatted_s(:rfc822)
    
    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.link post_url(slug: post.slug)
        xml.description do
          xml.cdata! render(partial: 'feed_item', locals: { post: post })
        end
        xml.pubDate post.published_on&.to_formatted_s(:rfc822) || post.created_at.to_formatted_s(:rfc822)
        xml.guid post_url(slug: post.slug), isPermaLink: true
        xml.author "noreply@chillfiltr.com (CHILLFILTR®)"
        if post.topic.present?
          xml.category post.topic.titleize
        end
        if post.tags.present?
          post.tags_from_hash.each do |tag|
            xml.category tag.strip
          end
        end
      end
    end
  end
end