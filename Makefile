.PHONY: logs upgrade help logs-% upgrade-%

# Mappings (short name -> deployment/release/chart/values)
DEPLOYMENT_profile = profile-service
DEPLOYMENT_image   = image-service
DEPLOYMENT_collector   = analytics-collector
DEPLOYMENT_analytics   = analytics-engine

RELEASE_profile = profile-service
CHART_profile   = applications/profile-service/
VALUES_profile  = applications/profile-service/values-local.yaml

RELEASE_image = image-service
CHART_image   = applications/image-service/
VALUES_image  = applications/image-service/values-local.yaml

RELEASE_collector = analytics-collector
CHART_collector   = applications/analytics-collector/
VALUES_collector  = applications/analytics-collector/values-local.yaml

RELEASE_engine = analytics-engine
CHART_engine   = applications/analytics-engine/
VALUES_engine  = applications/analytics-engine/values-local.yaml

# Convenience targets that accept service names as additional goals:
# Example: `make logs profile` or `make upgrade collector engine`
logs:
	@$(if $(filter-out $@,$(MAKECMDGOALS)),,$(error Usage: make logs <service> ...))
	@$(foreach svc,$(filter-out $@,$(MAKECMDGOALS)), $(MAKE) logs-$(svc);)

upgrade:
	@$(if $(filter-out $@,$(MAKECMDGOALS)),,$(error Usage: make upgrade <service> ...))
	@$(foreach svc,$(filter-out $@,$(MAKECMDGOALS)), $(MAKE) upgrade-$(svc);)

# Pattern rules invoked by the convenience targets above
logs-%:
	@echo "kubectl logs deployment/$(DEPLOYMENT_$*) -f"
	kubectl logs deployment/$(DEPLOYMENT_$*) -f

upgrade-%:
	@echo "helm upgrade -i $(RELEASE_$*) $(CHART_$*) -f $(VALUES_$*)"
	helm upgrade -i $(RELEASE_$*) $(CHART_$*) -f $(VALUES_$*)

help:
	@echo "Usage:"
	@echo "  make logs <service>     # e.g. make logs profile"
	@echo "  make upgrade <service>  # e.g. make upgrade collector"
