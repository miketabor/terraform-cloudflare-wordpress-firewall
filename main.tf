terraform {
  required_version = ">= 1.1.4"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.7.0"
    }
  }
}

# Get users Cloudflare API token.
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

# Get domain name to apply firewall rules.
variable "domain_name" {
  description = "Domain name to apply rules to"
  type        = string
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "cloudflare_zones" "website" {
  filter {
    name = var.domain_name
  }
}

# Challenge the wp-login / wp-admin logins if not from certain IP or IP ranges.
resource "cloudflare_filter" "wordpress_admin_login" {
  zone_id     = data.cloudflare_zones.website.zones[0].id
  description = "Wordpress Login Challenge"
  expression  = "(http.request.uri.path contains \"/wp-login.php\" and not ip.src in {x.x.x.x})" #replace x.x.x.x with your IP address.
}

resource "cloudflare_firewall_rule" "wordpress_admin_login" {
  zone_id     = data.cloudflare_zones.website.zones[0].id
  description = cloudflare_filter.wordpress_admin_login.description
  filter_id   = cloudflare_filter.wordpress_admin_login.id
  action      = "challenge"
}

# Block bad bots.
resource "cloudflare_filter" "block_bad_bots" {
  zone_id     = data.cloudflare_zones.website.zones[0].id
  description = "Block Bad Bots"
  expression  = "(lower(http.user_agent) contains \"acapbot\") or (lower(http.user_agent) contains \"acoonbot\") or (lower(http.user_agent) contains \"ahrefsbot\") or (lower(http.user_agent) contains \"attackbot\") or (lower(http.user_agent) contains \"backdorbot\") or (lower(http.user_agent) contains \"becomebot\") or (lower(http.user_agent) contains \"blackwidow\") or (lower(http.user_agent) contains \"blekkobot\") or (lower(http.user_agent) contains \"blexbot\") or (lower(http.user_agent) contains \"bunnys\") or (lower(http.user_agent) contains \"casper\") or (lower(http.user_agent) contains \"checkpriv\") or (lower(http.user_agent) contains \"cheesebot\") or (lower(http.user_agent) contains \"chinaclaw\") or (lower(http.user_agent) contains \"choppy\") or (lower(http.user_agent) contains \"cmsworld\") or (lower(http.user_agent) contains \"copyrightcheck\") or (lower(http.user_agent) contains \"datacha\") or (lower(http.user_agent) contains \"discobot\") or (lower(http.user_agent) contains \"dotbot\") or (lower(http.user_agent) contains \"dotnetdotcom\") or (lower(http.user_agent) contains \"dumbot\") or (lower(http.user_agent) contains \"emailcollector\") or (lower(http.user_agent) contains \"emailsiphon\") or (lower(http.user_agent) contains \"emailwolf\") or (lower(http.user_agent) contains \"extract\") or (lower(http.user_agent) contains \"flaming\") or (lower(http.user_agent) contains \"foobot\") or (lower(http.user_agent) contains \"g00g1e\") or (lower(http.user_agent) contains \"gigabot\") or (lower(http.user_agent) contains \"go-ahead-got\") or (lower(http.user_agent) contains \"gozilla\") or (lower(http.user_agent) contains \"grabnet\") or (lower(http.user_agent) contains \"harvest\") or (lower(http.user_agent) contains \"httrack\") or (lower(http.user_agent) contains \"jetbot\") or (lower(http.user_agent) contains \"kmccrew\") or (lower(http.user_agent) contains \"linkextractor\") or (lower(http.user_agent) contains \"linkscan\") or (lower(http.user_agent) contains \"linkwalker\") or (lower(http.user_agent) contains \"loader\") or (lower(http.user_agent) contains \"mechanize\") or (lower(http.user_agent) contains \"miner\") or (lower(http.user_agent) contains \"netmechanic\") or (lower(http.user_agent) contains \"netspider\") or (lower(http.user_agent) contains \"ninja\") or (lower(http.user_agent) contains \"octopus\") or (lower(http.user_agent) contains \"pagegrabber\") or (lower(http.user_agent) contains \"petalbot\") or (lower(http.user_agent) contains \"planetwork\") or (lower(http.user_agent) contains \"postrank\") or (lower(http.user_agent) contains \"pycurl\") or (lower(http.user_agent) contains \"queryn\") or (lower(http.user_agent) contains \"queryseeker\") or (lower(http.user_agent) contains \"scooter\") or (lower(http.user_agent) contains \"seekerspider\") or (lower(http.user_agent) contains \"semrushbot\") or (lower(http.user_agent) contains \"sindice\") or (lower(http.user_agent) contains \"sitebot\") or (lower(http.user_agent) contains \"siteexplorer\") or (lower(http.user_agent) contains \"sitesnagger\") or (lower(http.user_agent) contains \"smartdownload\") or (lower(http.user_agent) contains \"sogou\") or (lower(http.user_agent) contains \"sosospider\") or (lower(http.user_agent) contains \"spankbot\") or (lower(http.user_agent) contains \"spbot\") or (lower(http.user_agent) contains \"sqlmap\") or (lower(http.user_agent) contains \"stackrambler\") or (lower(http.user_agent) contains \"stripper\") or (lower(http.user_agent) contains \"sucker\") or (lower(http.user_agent) contains \"suzukacz\") or (lower(http.user_agent) contains \"suzuran\") or (lower(http.user_agent) contains \"teleport\") or (lower(http.user_agent) contains \"telesoft\") or (lower(http.user_agent) contains \"true_robots\") or (lower(http.user_agent) contains \"turingos\") or (lower(http.user_agent) contains \"vampire\") or (lower(http.user_agent) contains \"webwhacker\") or (lower(http.user_agent) contains \"whatcms\") or (lower(http.user_agent) contains \"woxbot\") or (lower(http.user_agent) contains \"wpscan\") or (lower(http.user_agent) contains \"xaldon\") or (lower(http.user_agent) contains \"yamanalab\") or (lower(http.user_agent) contains \"zmeu\")"
}

resource "cloudflare_firewall_rule" "block_bad_bots" {
  zone_id     = data.cloudflare_zones.website.zones[0].id
  description = cloudflare_filter.block_bad_bots.description
  filter_id   = cloudflare_filter.block_bad_bots.id
  action      = "block"
}

# Block access to sensitive Wordpress files and locations.
resource "cloudflare_filter" "wordpress_content_protection" {
  zone_id     = data.cloudflare_zones.website.zones[0].id
  description = "Wordpress Content Protection"
  expression  = "(cf.threat_score gt 14) or (http.request.full_uri contains \"wp-config.\") or (http.request.uri.path contains \"/wp-content/\" and http.request.uri.path contains \".php\") or (http.request.uri.path contains \"phpmyadmin\") or (http.request.uri.path contains \"/xmlrpc.php\") or (http.request.full_uri contains \"passwd\") or (http.request.uri.query contains \"author_name=\") or (http.request.uri.query contains \"author=\" and not http.request.uri.path contains \"/wp-admin/export.php\") or (http.request.uri contains \"/wp-json/wp/v2/users/\") or (http.request.full_uri contains \"../\") or (http.request.full_uri contains \"..%2F\") or (http.request.full_uri contains \"vuln.\") or (http.request.uri.query contains \"base64\") or (http.request.uri.query contains \"<script\") or (http.request.uri.query contains \"%3Cscript\") or (http.request.uri.query contains \"$_GLOBALS[\") or (http.request.uri.query contains \"$_REQUEST[\") or (http.request.uri.query contains \"$_POST[\") or (http.request.uri contains \"<?php\") or  (http.request.uri contains \".sql\") or (http.request.uri contains \".bak\") or (http.request.uri contains \".cfg\") or (http.request.uri contains \".env\") or (http.request.uri contains \".ini\") or (http.request.uri contains \".log\") or (http.request.full_uri contains \"/license.txt\") or (http.request.full_uri contains \"/readme.html\")"
}

resource "cloudflare_firewall_rule" "wordpress_content_protection" {
  zone_id     = data.cloudflare_zones.website.zones[0].id
  description = cloudflare_filter.wordpress_content_protection.description
  filter_id   = cloudflare_filter.wordpress_content_protection.id
  action      = "block"
}
