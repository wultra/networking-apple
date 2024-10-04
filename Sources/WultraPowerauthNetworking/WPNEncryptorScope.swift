//
// Copyright 2024 Wultra s.r.o.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions
// and limitations under the License.
//

import Foundation

/// End to end encryption configuration for an endpoint.
public enum WPNE2EEConfiguration {
    /// Endpoint is encrypted with the application scope.
    case applicationScope
    /// Endpoint is encrypted with the activation scope.
    case activationScope
    /// Endpoint is not encrypted.
    case notEncrypted
}
