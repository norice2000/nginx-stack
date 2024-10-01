FROM ghcr.io/terraform-linters/tflint:v0.53.0

COPY ./config/.tflint.hcl /config/.tflint.hcl

RUN tflint --init --config /config/.tflint.hcl
