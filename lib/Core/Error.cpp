//===- Error.cpp - system_error extensions for lld --------------*- C++ -*-===//
//
//                             The LLVM Linker
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "lld/Core/Error.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Support/ErrorHandling.h"
#include <mutex>
#include <string>
#include <vector>

using namespace lld;

class _YamlReaderErrorCategory : public std::error_category {
public:
  const char* name() const LLVM_NOEXCEPT override {
    return "lld.yaml.reader";
  }

  std::string message(int ev) const override {
    switch (static_cast<YamlReaderError>(ev)) {
    case YamlReaderError::unknown_keyword:
      return "Unknown keyword found in yaml file";
    case YamlReaderError::illegal_value:
      return "Bad value found in yaml file";
    }
    llvm_unreachable("An enumerator of YamlReaderError does not have a "
                     "message defined.");
  }
};

const std::error_category &lld::YamlReaderCategory() {
  static _YamlReaderErrorCategory o;
  return o;
}

class _LinkerScriptReaderErrorCategory : public std::error_category {
public:
  const char *name() const LLVM_NOEXCEPT override {
    return "lld.linker-script.reader";
  }

  std::string message(int ev) const override {
    switch (static_cast<LinkerScriptReaderError>(ev)) {
    case LinkerScriptReaderError::success:
      return "Success";
    case LinkerScriptReaderError::parse_error:
      return "Error parsing linker script";
    case LinkerScriptReaderError::unknown_symbol_in_expr:
      return "Unknown symbol found when evaluating linker script expression";
    case LinkerScriptReaderError::unrecognized_function_in_expr:
      return "Unrecognized function call when evaluating linker script "
             "expression";
    case LinkerScriptReaderError::unknown_phdr_ids:
      return "Unknown header identifiers (missing in PHDRS command) are used";
    case LinkerScriptReaderError::extra_program_phdr:
      return "Extra program header is found";
    case LinkerScriptReaderError::misplaced_program_phdr:
      return "Program header must precede load segments";
    case LinkerScriptReaderError::program_phdr_wrong_phdrs:
      return "Program header has invalid PHDRS attribute";
    }
    llvm_unreachable("An enumerator of LinkerScriptReaderError does not have a "
                     "message defined.");
  }
};

const std::error_category &lld::LinkerScriptReaderCategory() {
  static _LinkerScriptReaderErrorCategory o;
  return o;
}

namespace lld {

/// Temporary class to enable make_dynamic_error_code() until
/// llvm::ErrorOr<> is updated to work with error encapsulations
/// other than error_code.
class dynamic_error_category : public std::error_category {
public:
  ~dynamic_error_category() override = default;

  const char *name() const LLVM_NOEXCEPT override {
    return "lld.dynamic_error";
  }

  std::string message(int ev) const override {
    assert(ev >= 0);
    assert(ev < (int)_messages.size());
    // The value is an index into the string vector.
    return _messages[ev];
  }

  int add(std::string msg) {
    std::lock_guard<std::recursive_mutex> lock(_mutex);
    // Value zero is always the successs value.
    if (_messages.empty())
      _messages.push_back("Success");
    _messages.push_back(msg);
    // Return the index of the string just appended.
    return _messages.size() - 1;
  }

private:
  std::vector<std::string> _messages;
  std::recursive_mutex _mutex;
};

static dynamic_error_category categorySingleton;

std::error_code make_dynamic_error_code(const char *msg) {
  return make_dynamic_error_code(StringRef(msg));
}

std::error_code make_dynamic_error_code(StringRef msg) {
  return std::error_code(categorySingleton.add(msg), categorySingleton);
}

std::error_code make_dynamic_error_code(const Twine &msg) {
  return std::error_code(categorySingleton.add(msg.str()), categorySingleton);
}

} // namespace lld
