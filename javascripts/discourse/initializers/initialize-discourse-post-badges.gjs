import { htmlSafe } from "@ember/template";
import { iconHTML } from "discourse/lib/icon-library";
import { withPluginApi } from "discourse/lib/plugin-api";

const BADGE_CLASS = [
  "badge-type-gold",
  "badge-type-silver",
  "badge-type-bronze",
];

const TRUST_LEVEL_BADGE = ["basic", "member", "regular", "leader"];

const USER_BADGE_PAGE = "user's badge page";

function buildBadge(badge) {
  let iconBody;

  if (badge.image) {
    const img = document.createElement("img");
    img.setAttribute("src", badge.image);
    iconBody = img.outerHTML;
  } else if (badge.icon) {
    iconBody = iconHTML(badge.icon);
  }

  if (badge.url) {
    const link = document.createElement("a");
    link.setAttribute("href", badge.url);
    link.innerHTML = iconBody;
    iconBody = link;
  }

  const span = document.createElement("span");
  span.classList.add("poster-icon");
  span.classList.add(badge.className);
  if (badge.id >= 1 && badge.id <= 4) {
    // trust level badge
    span.classList.add(TRUST_LEVEL_BADGE[badge.id - 1]);
  }
  span.setAttribute("title", badge.title);
  span.appendChild(iconBody);
  return span;
}

function prepareBadges(allSerializedBadges, displayedBadges, username) {
  let badgePage = "";

  const isUserBadgePage = settings.badge_link_destination === USER_BADGE_PAGE;
  if (isUserBadgePage) {
    badgePage = `?username=${username}`;
  }

  return allSerializedBadges
    .filter((badge) => displayedBadges.includes(badge.name.toLowerCase()))
    .map((badge) => {
      return {
        icon: badge.icon.replace("fa-", ""),
        image: badge.image_url ? badge.image_url : badge.image,
        className: BADGE_CLASS[badge.badge_type_id - 1],
        name: badge.slug,
        id: badge.id,
        badgeGroup: badge.badge_grouping_id,
        title: badge.description,
        url: `/badges/${badge.id}/${badge.slug}${badgePage}`,
      };
    });
}

function renderBadges(preparedBadges) {
  return htmlSafe(
    preparedBadges.map((badge) => buildBadge(badge).outerHTML).join("")
  );
}

export default {
  name: "discourse-post-badges",

  initialize(container) {
    withPluginApi((api) => {
      const site = container.lookup("service:site");
      const displayedBadges = settings.badges
        .split("|")
        .filter(Boolean)
        .map((badge) => badge.toLowerCase());

      function renderBadgeHtml(post) {
        if (post.userBadges) {
          const preparedBadges = prepareBadges(
            post.userBadges,
            displayedBadges,
            post.username
          );
          return renderBadges(preparedBadges);
        }
      }

      api.renderInOutlet(
        "post-meta-data-poster-name__before",
        <template>
          {{#if site.mobileView}}
            <div class="poster-icon-container">{{renderBadgeHtml @post}}</div>
          {{/if}}
        </template>
      );

      api.renderInOutlet(
        "post-meta-data-poster-name__after",
        <template>
          {{#if site.desktopView}}
            <div class="poster-icon-container">{{renderBadgeHtml @post}}</div>
          {{/if}}
        </template>
      );

      api.registerValueTransformer(
        "post-article-class",
        ({ value: classes, context }) => {
          let trustLevel = "";
          let highestBadge = 0;
          context.post.userBadges?.forEach((badge) => {
            if (badge.badge_grouping_id === 4 && badge.id > highestBadge) {
              highestBadge = badge.id;
              trustLevel = `${TRUST_LEVEL_BADGE[highestBadge - 1]}-highest`;
            }
          });

          if (trustLevel) {
            classes.push(trustLevel);
          }

          return classes;
        }
      );
    });
  },
};
