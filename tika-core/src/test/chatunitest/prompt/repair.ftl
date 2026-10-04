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
Repair the following JUnit Jupiter test for `${method_sig}` in `${class_name}`:

```java
${unit_test}
```

The validator reported:
```
${error_message}
```

The authoritative focal-method context is:
```${full_fm}```

<#if method_sig?starts_with("normalizeMediaType(")>
Call `EmbeddedDocumentUtil.normalizeMediaType` statically. Assert `"image/png"` for `"image/ocr-png"`, `"image/jpeg"` for `"image/jpeg"`, and null for null. Remove mocks and focal-class construction.
<#elseif method_sig?starts_with("getExtension(")>
The passing repair must use a real `Metadata` with `Metadata.CONTENT_TYPE` set to `"application/pdf"`, a focal object constructed from a real `ParseContext`, and `TikaInputStream.get(new byte[0])` in try-with-resources; assert `".pdf"`. Do not test `Detector.detect` itself.
<#elseif method_sig?starts_with("getExtensionForMediaType(")>
Delete any direct `MimeType` or `MimeTypes` calls. Call `EmbeddedDocumentUtil.getExtensionForMediaType` and assert `".pdf"` for `"application/pdf"`, `".png"` for `"image/ocr-png"`, and `""` for null.
<#elseif method_sig?starts_with("generateResourceName(")>
Replace every unqualified or nonexistent enum reference with exactly `EmbeddedDocumentUtil.EmbeddedResourcePrefix.EMBEDDED`, and assert `"embedded-1.pdf"`.
<#elseif method_sig?starts_with("recordEmbeddedStreamException(")>
Use a Mockito `Metadata` mock and verify the value passed to `add` is exactly `ExceptionUtils.getFilteredStackTrace(exception)`; do not use a literal stack-trace string.
<#elseif method_sig?starts_with("shouldParseEmbedded(")>
Replace invented metadata constants and static calls with an `EmbeddedDocumentExtractor` mock stored in a real `ParseContext`; construct the focal object, stub the mock's `shouldParseEmbedded`, call the instance method, and verify delegation.
<#elseif method_sig?starts_with("parseEmbedded(")>
Replace constructed streams and anonymous handlers with Mockito mocks for `TikaInputStream` and `ContentHandler`. Store an `EmbeddedDocumentExtractor` mock in a real `ParseContext`, construct the focal object, call it, and verify `extractor.parseEmbedded(input, handler, metadata, context, true)`.
</#if>

<#if other_method_sigs?has_content>
Other focal-class signatures are `${other_method_sigs}`.
</#if>

Correct the test rather than changing dependencies or production code. Re-evaluate every assertion from the focal source; an assertion failure means the expected behavior in the test is wrong. Return exactly one complete Java compilation unit inside exactly one ```java code fence and no prose.
