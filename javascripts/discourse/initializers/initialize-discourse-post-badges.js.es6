import { ajax } from "discourse/lib/ajax";
import { withPluginApi } from "discourse/lib/plugin-api";
import { iconHTML } from "discourse-common/lib/icon-library";
import { schedule } from "@ember/runloop";
import { makeArray } from "discourse-common/lib/helpers";

const BADGE_CLASS = [
  "badge-type-gold",
  "badge-type-silver",
  "badge-type-bronze"
];

const TRUST_LEVEL_BADGE = [
  "basic",
  "member",
  "regular",
  "leader"
];

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
  span.classList.add(TRUST_LEVEL_BADGE[badge.id - 1]);
  span.setAttribute("title", badge.title);
  span.appendChild(iconBody);
  return span;
}

function loadUserBadges(username, displayedBadges) {
  return ajax(`/user-badges/${username}.json`).then(response => {
    let badgePage = "";

    const isUserBadgePage = settings.badge_link_destination === USER_BADGE_PAGE;
    if (isUserBadgePage) {
      badgePage = `?username=${username}`;
    }

    return makeArray(response.badges)
      .filter(badge => displayedBadges.includes(badge.name.toLowerCase()))
      .map(badge => {
        return {
          icon: badge.icon.replace("fa-", ""),
          image: badge.image,
          className: BADGE_CLASS[badge.badge_type_id - 1],
          name: badge.name,
          id: badge.id,
          badgeGroup: badge.badge_grouping_id,
          title: badge.name,
          description: badge.description,
          url: `/badges/${badge.id}/${badge.slug}${badgePage}`
        };
      });
  });
}

function appendBadges(badges, decorator) {
  const selector = `[data-post-id="${
    decorator.attrs.id
  }"] .poster-icon-container`;

  let trustLevel = "";
  let highestBadge = 0;
  const badgesNodes = [];
  badges.forEach(badge => {
    badgesNodes.push(buildBadge(badge));
    if (badge.badgeGroup === 4 && badge.id > highestBadge) {
      highestBadge = badge.id;
      trustLevel = `${TRUST_LEVEL_BADGE[highestBadge - 1]}-highest`;
    }
  });

  schedule("afterRender", () => {
    const postContainer = document.querySelector(selector);
    if (postContainer) {
      postContainer.innerHTML = "";
      trustLevel && postContainer.classList.add(trustLevel);
      badgesNodes.forEach(badgeNode => postContainer.appendChild(badgeNode));
    }
  });
}

export default {
  name: "discourse-post-badges",

  initialize() {
    withPluginApi("0.8.25", api => {
      const isMobileView = Discourse.Site.currentProp("mobileView");
      const location = isMobileView ? "before" : "after";
      const displayedBadges = settings.badges
        .split("|")
        .filter(Boolean)
        .map(badge => badge.toLowerCase());

      api.decorateWidget(`poster-name:${location}`, decorator => {
        const username = decorator.attrs.username;
        loadUserBadges(username, displayedBadges).then(badges =>
          appendBadges(badges, decorator)
        );

        return decorator.h("div.poster-icon-container", {}, []);
      });
    });
  }
};
