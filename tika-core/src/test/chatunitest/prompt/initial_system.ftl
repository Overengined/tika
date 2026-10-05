<#--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements. See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License. You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
You are generating a production-quality JUnit Jupiter test for Apache Tika.

Return exactly one complete Java compilation unit inside exactly one ```java code fence. Do not return prose, a second code fence, XML, Maven dependencies, or alternative implementations.

The generated test must compile and every assertion must pass against the focal source exactly as supplied. Derive expected values and null behavior directly from that source. Do not invent behavior, constructors, overloads, constants, or return values. In particular:
- If the focal source returns null for the arranged state, assert null rather than non-null.
- For a static focal method, invoke it statically and do not instantiate the focal class.
- For a delegating method, mock the documented dependency, configure it through the supplied ParseContext, and verify the exact delegation.
- For void methods, verify observable state or mock interactions; never place a void invocation inside an assertion value.
- Qualify nested types with their enclosing class unless they are explicitly imported.
- Use TikaInputStream where the signature requires it; do not substitute InputStream, URI, URL, or Blob.
- Use only APIs visible in the supplied context and dependencies already available to the project.
- Prefer small tests with explicit arrangements over speculative integration behavior.

Use JUnit Jupiter and Mockito only when mocking is necessary. Cover meaningful branches without asserting assumptions that are absent from the source.
