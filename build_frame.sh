#!/bin/bash

set -euo pipefail

project=""
target_name=""
build_configuration="Release"
version=""
zip_flag=false
delete_string=""

root_dir="$(cd "$(dirname "$0")" && pwd)"
target_root=""
target_root_dir=""
temp_iphone_output_dir=""
temp_iphonesimulator_output_dir=""
target_file=""
target_dsym_file=""

refresh_paths() {
  target_root="${root_dir}/build"
  target_root_dir="${target_root}/${target_name}"
  temp_iphone_output_dir="${target_root_dir}/build-iphone"
  temp_iphonesimulator_output_dir="${target_root_dir}/build-iphonesimulator"
  target_file="${target_name}_iOS_v${version}.framework.zip"
  target_dsym_file="${target_name}_iOS_v${version}.dSYM.zip"
}

print_env() {
  echo "----- start build ${target_name} -----"
  echo "project=${project}"
  echo "target_name=${target_name}"
  echo "build_configuration=${build_configuration}"
  echo "version=${version}"
  echo "root_dir=${root_dir}"
  echo "target_root_dir=${target_root_dir}"
  echo "target_file=${target_file}"
  echo "target_dsym_file=${target_dsym_file}"
  echo "--------------------------------------"
}

setup_env() {
  rm -rf "${target_root_dir}"
  rm -f "${target_root}/${target_file}"
  rm -f "${target_root}/${target_dsym_file}"
  mkdir -p "${target_root_dir}"
}

build_framework_release() {
  rm -rf "${temp_iphone_output_dir}" "${temp_iphonesimulator_output_dir}"

  xcodebuild \
    -configuration "${build_configuration}" \
    -project "${project}" \
    -target "${target_name}" \
    -sdk iphoneos \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    ONLY_ACTIVE_ARCH=NO \
    CLANG_ENABLE_EXPLICIT_MODULES=NO \
    CONFIGURATION_BUILD_DIR="${temp_iphone_output_dir}" \
    build

  if [[ ! -f "${temp_iphone_output_dir}/${target_name}.framework/${target_name}" ]]; then
    echo "{iphoneos} failed to export ${target_name}.framework"
    exit 1
  fi

  xcodebuild \
    -configuration "${build_configuration}" \
    -project "${project}" \
    -target "${target_name}" \
    -sdk iphonesimulator \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    ONLY_ACTIVE_ARCH=NO \
    CLANG_ENABLE_EXPLICIT_MODULES=NO \
    CONFIGURATION_BUILD_DIR="${temp_iphonesimulator_output_dir}" \
    build

  if [[ ! -f "${temp_iphonesimulator_output_dir}/${target_name}.framework/${target_name}" ]]; then
    echo "{iphonesimulator} failed to export ${target_name}.framework"
    exit 1
  fi
}

apply_interface_rewrites() {
  if [[ -z "${delete_string}" ]]; then
    return
  fi

  echo "start delete string ${delete_string} ..."
  local tokens
  tokens=($(echo "${delete_string}" | sed 's#/# #g'))
  while IFS= read -r swiftinterface; do
    for token in "${tokens[@]}"; do
      sed -i "" "s/${token}\.//g" "${swiftinterface}"
    done
  done < <(find "${target_root_dir}" -name "*.swiftinterface")
}

validate_objc_framework_headers() {
  local rewriter="${root_dir}/scripts/fix_oc_framework_headers.py"
  if [[ ! -f "${rewriter}" ]]; then
    echo "missing header validation script: ${rewriter}"
    exit 1
  fi

  for framework in \
    "${temp_iphone_output_dir}/${target_name}.framework" \
    "${temp_iphonesimulator_output_dir}/${target_name}.framework"; do
    if [[ -d "${framework}/Headers" ]]; then
      python3 "${rewriter}" \
        --framework "${framework}" \
        --module "${target_name}" \
        --source-root "${root_dir}" \
        --dry-run \
        --fail-on-rewrite \
        --fail-on-unresolved-relative
    fi
  done
}

export_framework() {
  validate_objc_framework_headers

  xcodebuild -create-xcframework \
    -framework "${temp_iphone_output_dir}/${target_name}.framework" \
    -framework "${temp_iphonesimulator_output_dir}/${target_name}.framework" \
    -output "${target_root_dir}/${target_name}.xcframework"

  if [[ -d "${temp_iphone_output_dir}/${target_name}.dSYM" ]]; then
    cp -R "${temp_iphone_output_dir}/${target_name}.dSYM" "${target_root_dir}/${target_name}.dSYM"
  fi

  apply_interface_rewrites

  if [[ ! -d "${target_root_dir}/${target_name}.xcframework" ]]; then
    echo "failed to export ${target_name}.xcframework"
    exit 1
  fi
}

build_after() {
  if [[ "${zip_flag}" != true ]]; then
    return
  fi

  (
    cd "${target_root_dir}"
    zip -qry "${target_root}/${target_file}" "${target_name}.xcframework"
    if [[ -d "${target_name}.dSYM" ]]; then
      zip -qry "${target_root}/${target_dsym_file}" "${target_name}.dSYM"
    fi
  )
}

show_usage() {
  echo "Usage:"
  echo "  sh build_frame.sh --project Pods/Pods.xcodeproj --targetName NEContactUIKitOC --version 1.0.0 -z"
  exit 1
}

params=("$@")
for ((i = 0; i < ${#params[@]}; i++)); do
  cur="${params[i]}"
  next="${params[i+1]:-}"
  case "${cur}" in
    --project)
      project="${next}"
      ((i++))
      ;;
    --targetName)
      target_name="${next}"
      ((i++))
      ;;
    --version)
      version="${next}"
      ((i++))
      ;;
    --delete)
      delete_string="${next}"
      ((i++))
      ;;
    -d)
      build_configuration="Debug"
      ;;
    -r)
      build_configuration="Release"
      ;;
    -z)
      zip_flag=true
      ;;
    *)
      show_usage
      ;;
  esac
done

if [[ -z "${project}" || -z "${target_name}" || -z "${version}" ]]; then
  show_usage
fi

refresh_paths
print_env

if [[ "${build_configuration}" != "Release" ]]; then
  show_usage
fi

setup_env
build_framework_release
export_framework
build_after
