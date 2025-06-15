document.addEventListener("DOMContentLoaded", function () {

   var countryLanguageMap = {
      "af-za": {
         "country": "South Africa",
         "language": "Afrikaans"
      },
      "am-et": {
         "country": "Ethiopia",
         "language": "አማርኛ (Amharic)"
      },
      "ar-ae": {
         "country": "United Arab Emirates",
         "language": "العربية (Arabic)"
      },
      "ar-bh": {
         "country": "Bahrain",
         "language": "العربية (Arabic)"
      },
      "ar-dz": {
         "country": "Algeria",
         "language": "العربية (Arabic)"
      },
      "ar-eg": {
         "country": "Egypt",
         "language": "العربية (Arabic)"
      },
      "ar-iq": {
         "country": "Iraq",
         "language": "العربية (Arabic)"
      },
      "ar-jo": {
         "country": "Jordan",
         "language": "العربية (Arabic)"
      },
      "ar-kw": {
         "country": "Kuwait",
         "language": "العربية (Arabic)"
      },
      "ar-lb": {
         "country": "Lebanon",
         "language": "العربية (Arabic)"
      },
      "ar-ly": {
         "country": "Libya",
         "language": "العربية (Arabic)"
      },
      "ar-ma": {
         "country": "Morocco",
         "language": "العربية (Arabic)"
      },
      "ar-om": {
         "country": "Oman",
         "language": "العربية (Arabic)"
      },
      "ar-qa": {
         "country": "Qatar",
         "language": "العربية (Arabic)"
      },
      "ar-sa": {
         "country": "Saudi Arabia",
         "language": "العربية (Arabic)"
      },
      "ar-sy": {
         "country": "Syria",
         "language": "العربية (Arabic)"
      },
      "ar-tn": {
         "country": "Tunisia",
         "language": "العربية (Arabic)"
      },
      "ar-ye": {
         "country": "Yemen",
         "language": "العربية (Arabic)"
      },
      "az-az": {
         "country": "Azerbaijan",
         "language": "Azərbaycanca (Azerbaijani)"
      },
      "be-by": {
         "country": "Belarus",
         "language": "Беларуская (Belarusian)"
      },
      "bg-bg": {
         "country": "Bulgaria",
         "language": "Български (Bulgarian)"
      },
      "bn-bd": {
         "country": "Bangladesh",
         "language": "বাংলা (Bengali)"
      },
      "bs-ba": {
         "country": "Bosnia and Herzegovina",
         "language": "Bosanski (Bosnian)"
      },
      "ca-es": {
         "country": "Spain",
         "language": "Català (Catalan)"
      },
      "cs-cz": {
         "country": "Czech Republic",
         "language": "Čeština (Czech)"
      },
      "da-dk": {
         "country": "Denmark",
         "language": "Dansk (Danish)"
      },
      "de-at": {
         "country": "Austria",
         "language": "Deutsch (German)"
      },
      "de-ch": {
         "country": "Switzerland",
         "language": "Deutsch (German)"
      },
      "de-de": {
         "country": "Germany",
         "language": "Deutsch (German)"
      },
      "el-gr": {
         "country": "Greece",
         "language": "Ελληνικά (Greek)"
      },
      "en-au": {
         "country": "Australia",
         "language": "English (English)"
      },
      "en-ca": {
         "country": "Canada",
         "language": "English (English)"
      },
      "en-gb": {
         "country": "United Kingdom",
         "language": "English (English)"
      },
      "en-in": {
         "country": "India",
         "language": "English (English)"
      },
      "en-nz": {
         "country": "New Zealand",
         "language": "English (English)"
      },
      "en-us": {
         "country": "United States",
         "language": "English (English)"
      },
      "es-ar": {
         "country": "Argentina",
         "language": "Español (Spanish)"
      },
      "es-cl": {
         "country": "Chile",
         "language": "Español (Spanish)"
      },
      "es-co": {
         "country": "Colombia",
         "language": "Español (Spanish)"
      },
      "es-es": {
         "country": "Spain",
         "language": "Español (Spanish)"
      },
      "es-mx": {
         "country": "Mexico",
         "language": "Español (Spanish)"
      },
      "et-ee": {
         "country": "Estonia",
         "language": "Eesti (Estonian)"
      },
      "fi-fi": {
         "country": "Finland",
         "language": "Suomi (Finnish)"
      },
      "fr-be": {
         "country": "Belgium",
         "language": "Français (French)"
      },
      "fr-ca": {
         "country": "Canada",
         "language": "Français (French)"
      },
      "fr-fr": {
         "country": "France",
         "language": "Français (French)"
      },
      "he-il": {
         "country": "Israel",
         "language": "עברית (Hebrew)"
      },
      "hi-in": {
         "country": "India",
         "language": "हिन्दी (Hindi)"
      },
      "hr-hr": {
         "country": "Croatia",
         "language": "Hrvatski (Croatian)"
      },
      "hu-hu": {
         "country": "Hungary",
         "language": "Magyar (Hungarian)"
      },
      "id-id": {
         "country": "Indonesia",
         "language": "Bahasa (Indonesian)"
      },
      "it-it": {
         "country": "Italy",
         "language": "Italiano (Italian)"
      },
      "ja-jp": {
         "country": "Japan",
         "language": "日本語 (Japanese)"
      },
      "ko-kr": {
         "country": "South Korea",
         "language": "한국어 (Korean)"
      },
      "lt-lt": {
         "country": "Lithuania",
         "language": "Lietuvių (Lithuanian)"
      },
      "lv-lv": {
         "country": "Latvia",
         "language": "Latviešu (Latvian)"
      },
      "ms-my": {
         "country": "Malaysia",
         "language": "Bahasa Melayu (Malay)"
      },
      "nb-no": {
         "country": "Norway",
         "language": "Norsk Bokmål (Norwegian)"
      },
      "nl-be": {
         "country": "Belgium",
         "language": "Nederlands (Dutch)"
      },
      "nl-nl": {
         "country": "Netherlands",
         "language": "Nederlands (Dutch)"
      },
      "pl-pl": {
         "country": "Poland",
         "language": "Polski (Polish)"
      },
      "pt-br": {
         "country": "Brazil",
         "language": "Português (Portuguese)"
      },
      "pt-pt": {
         "country": "Portugal",
         "language": "Português (Portuguese)"
      },
      "ro-ro": {
         "country": "Romania",
         "language": "Română (Romanian)"
      },
      "ru-ru": {
         "country": "Russia",
         "language": "Русский (Russian)"
      },
      "sv-se": {
         "country": "Sweden",
         "language": "Svenska (Swedish)"
      },
      "th-th": {
         "country": "Thailand",
         "language": "ไทย (Thai)"
      },
      "tr-tr": {
         "country": "Turkey",
         "language": "Türkçe (Turkish)"
      },
      "uk-ua": {
         "country": "Ukraine",
         "language": "Українська (Ukrainian)"
      },
      "zh-cn": {
         "country": "China",
         "language": "中文 (Simplified Chinese)"
      }
   };
   const mastheadContainer = document.querySelector("c4d-masthead-container");

   const countryBtn = document.querySelector('.earth-language-icon');
   var countrySwitcher = document.createElement("div");
   countrySwitcher.id = "countrySwitcher";

   var countryDropdown = document.createElement("div");
   countryDropdown.id = "countryDropdown";
   countryDropdown.className = "hidden";

   var currentRegionText = document.createElement("div");
   currentRegionText.id = "currentRegion";
   countryDropdown.appendChild(currentRegionText);

   var countryList = document.createElement("ul");
   countryList.id = "countryList";
   countryDropdown.appendChild(countryList);

   countrySwitcher.appendChild(countryDropdown);
   var mastheadProfile = document.querySelector("c4d-masthead-profile");
   if (countryBtn) {
      countryBtn.appendChild(countrySwitcher);
   }

   function capitalize(text) {
      return text.charAt(0).toUpperCase() + text.slice(1);
   }

   function capitalizeWords(text) {
      return text.split(' ').map(word => capitalize(word)).join(' ');
   }

   function getCurrentRegion() {
      const countryCodeMeta = document.querySelector("meta[name='countryCode']");
      const languageCodeMeta = document.querySelector("meta[name='languageCode']");

      if (!countryCodeMeta || !languageCodeMeta) {
         return { country: "Unknown", language: "Unknown" };
      }

      const countryCode = countryCodeMeta.content.toUpperCase();
      const languageCode = languageCodeMeta.content.toLowerCase();

      const displayNames = new Intl.DisplayNames(languageCode, { type: 'region' });
      const languageDisplayNames = new Intl.DisplayNames(languageCode, { type: 'language' });

      let regionName = displayNames.of(countryCode) || countryCode;
      let languageName = languageDisplayNames.of(languageCode) || languageCode;

      if (languageName.toLowerCase() === "chinese") {
         languageName = "Simplified Chinese";
      }

      return {
         country: capitalize(regionName),
         language: capitalize(languageName)
      };
   }

   function categorizeLinks() {
      const links = document.querySelectorAll("link[rel='alternate']");
      const categorizedLinks = [];
      const currentRegion = getCurrentRegion();

      const metaTag = document.querySelector("meta[name='languageCode']");
      const displayNames = new Intl.DisplayNames(metaTag.content.toLowerCase(), { type: 'region' });
      const languageDisplayNames = new Intl.DisplayNames(metaTag.content.toLowerCase(), { type: 'language' });

      links.forEach(link => {
         const hreflang = link.getAttribute("hreflang");
         const href = link.getAttribute("href");

         if (countryLanguageMap[hreflang]) {
            const regionCode = hreflang.split('-')[1].toUpperCase();
            let translatedCountryName = displayNames.of(regionCode) || countryLanguageMap[hreflang].country;
            const originalLanguage = countryLanguageMap[hreflang].language;
            let translatedLanguage = originalLanguage;

            const bracketMatch = originalLanguage.match(/\((.*?)\)/);
            if (bracketMatch) {
               const bracketText = bracketMatch[1];
               const languageCode = hreflang.split('-')[0];
               let translatedBracketText = languageDisplayNames.of(languageCode) || bracketText;

               if (translatedBracketText.toLowerCase() === "chinese") {
                  translatedBracketText = "Simplified Chinese";
               }

               translatedBracketText = capitalizeWords(translatedBracketText);

               if (originalLanguage.trim().toLowerCase() === "english (english)") {
                  translatedLanguage = "English (".concat(translatedBracketText).concat(")");
               } else {
                  translatedLanguage = originalLanguage.replace(bracketText, translatedBracketText);
               }
            }

            translatedCountryName = capitalize(translatedCountryName);
            translatedLanguage = capitalize(translatedLanguage);

            if (hreflang !== metaTag.content.toLowerCase().concat("-").concat(document.querySelector("meta[name='countryCode']").content.toLowerCase())
               && translatedCountryName !== currentRegion.country) {

               categorizedLinks.push({
                  hreflang: hreflang,
                  href: href,
                  countryInfo: {
                     country: translatedCountryName,
                     language: translatedLanguage
                  }
               });
            }
         }
      });

      return categorizedLinks;
   }

   function displayCategorizedLinks() {
      countryList.innerHTML = "";
      const isHidden = countryDropdown.classList.toggle("hidden");
      if (isHidden) {
         countryBtn.removeAttribute("expanded");
      } else {
         countryBtn.setAttribute("expanded", "");
      }

      var currentRegion = getCurrentRegion();
      var l0CurrentRegionText = mastheadContainer.getAttribute("current-region-text") + ":";
      var l0DifferentRegionText = mastheadContainer.getAttribute("different-region-text") + ":";
      var l0NoOtherRegionsText = mastheadContainer.getAttribute("no-other-region-text") + ".";

      currentRegionText.innerHTML =
         '<div class="current-region-label">' + l0CurrentRegionText + '</div>' +
         '<div class="current-region-value"><strong>' + currentRegion.country + ' – ' + currentRegion.language + '</strong></div>';
      currentRegionText.classList.add("current-region-container");
      var links = categorizeLinks();
      links = links.filter(link =>
         link.countryInfo.country !== currentRegion.country ||
         link.countryInfo.language !== currentRegion.language
      );
      var regionMessage = document.createElement("div");
      regionMessage.classList.add("region-selection");
      if (links.length === 0) {
         regionMessage.innerText = l0NoOtherRegionsText;
         countryList.appendChild(regionMessage);
         countryList.classList.remove("hidden");
         return;
      } else {
         regionMessage.innerHTML = l0DifferentRegionText;
         countryList.appendChild(regionMessage);
      }
      links.sort((a, b) => a.countryInfo.country.localeCompare(b.countryInfo.country));
      var listContainer = document.createElement("div");
      listContainer.classList.add("region-list-container");
      countryList.appendChild(listContainer);

      for (var i = 0; i < links.length; i++) {
         var listItem = document.createElement("li");
         listItem.innerText = links[i].countryInfo.country + " – " + links[i].countryInfo.language;
         listItem.onclick = (function (url) {
            return function () {
               window.open(url, "_self");
            };
         })(links[i].href);
         listContainer.appendChild(listItem);
      }
   }
   countryBtn.addEventListener('click', function () {
      event.preventDefault();
      if (!countryBtn.contains(countrySwitcher)) {
         countryBtn.appendChild(countrySwitcher);
      }

      displayCategorizedLinks();
   });

   document.addEventListener("click", function (event) {
      if (!countryBtn.contains(event.target) && event.target !== countryBtn) {
         countryDropdown.classList.add("hidden");
         countryBtn.removeAttribute("expanded");
      }
   });
});