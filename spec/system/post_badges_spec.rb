# frozen_string_literal: true

RSpec.describe "Post Badges theme component", system: true do
  let!(:theme) { upload_theme_component }
  let(:user) { Fabricate(:user) }
  let(:user2) { Fabricate(:user) }
  let(:post) { Fabricate(:post, user: user) }

  let!(:user_badge) { Fabricate(:user_badge, badge: Badge.find_by(name: "First Like"), user: user) }

  it "should display user badges on posts" do
    theme.update_setting(:badges, "first like")
    theme.save!

    visit "/t/#{post.topic_id}"

    expect(page).to have_selector("#post_1")
    badge = find("#post_1 .poster-icon-container .badge-type-bronze")
    expect(badge).to have_link(
      href: "/badges/#{user_badge.badge_id}/#{user_badge.badge.slug}?username=#{user.username}",
    )
  end

  it "should display user badges on filtered posts" do
    Fabricate(:post, user: user2)
    Fabricate(:post, user: user)

    theme.update_setting(:badges, "first like")
    theme.save!

    visit "/t/#{post.topic_id}"

    expect(page).to have_selector("#post_3")
    find("#post_3 .post-avatar").click
    expect(page).to have_selector("#user-card")
    find(".usercard-controls li button:has(svg.d-icon-filter)").click

    badge = find("#post_3 .poster-icon-container .badge-type-bronze")
    expect(badge).to have_link(
      href: "/badges/#{user_badge.badge_id}/#{user_badge.badge.slug}?username=#{user.username}",
    )
  end
end
