# 1. First we're going to want to deploy/update our security enforcement layer.
# TODO: Finish this module.
#module "open_policy_agent" {
#    source = "github.com/dylanturn/terraform-kubernetes-opa-gatekeeper"
#    namespace = var.opa_namespace
#}

# 2. Next we need to deploy/update the clusters service mesh.
# TODO: Finish this module.
#module "linkerd" {
#    source = "github.com/dylanturn/terraform-kubernetes-linkerd"
#    depends_on = [module.open_policy_agent]
#    namespace = var.linkerd_namespace
#}

# 3. Now we deploy/update the clusters ingress controller.
# TODO: Pat myself on the back for getting this to work.
module "traefik" {
  source = "github.com/dylanturn/terraform-kubernetes-traefik?ref=replace_helm"
  count  = var.traefik == null ? 0 : 1
  # depends_on = [module.open_policy_agent, module.linkerd]

  namespace                            = var.traefik.namespace
  log_level                            = var.traefik.log_level
  replicas                             = var.traefik.replicas
  rolling_update_max_surge             = var.traefik.rolling_update_max_surge
  rolling_update_max_unavailable       = var.traefik.rolling_update_max_unavailable
  pod_termination_grace_period_seconds = var.traefik.pod_termination_grace_period_seconds
}

# 4. Lastly, deploy/update the CICD orchestrator.
# TODO: Pat myself on the back for getting this to work.
module "argocd" {
  source     = "github.com/dylanturn/terraform-kubernetes-argocd"
  count      = var.argocd == null ? 0 : 1
  depends_on = [module.traefik]

  namespace              = var.argocd.namespace
  cluster_cert_issuer    = var.cluster_cert_issuer
  ingress_class          = var.cluster_ingress_class
  argocd_server_replicas = var.argocd.server_replicas
  argocd_repo_replicas   = var.argocd.repo_replicas
  enable_dex             = var.argocd.enable_dex
  enable_ha_redis        = var.argocd.enable_ha_redis
  oidc_config = {
    name                      = var.argocd.oidc_name,
    issuer                    = var.argocd.oidc_issuer,
    client_id                 = var.argocd.oidc_client_id,
    client_secret             = var.argocd.oidc_client_secret,
    requested_scopes          = var.argocd.oidc_requested_scopes,
    requested_id_token_claims = var.argocd.oidc_requested_id_token_claims
  }
}
