
# IFT3913 — Tâche 2 : Génération de tests et analyse de mutation

## Projet étudié

**Projet :** Apache Tika  
**Module :** `tika-core`  
**Classe sélectionnée :** `org.apache.tika.extractor.EmbeddedDocumentUtil`

Ce travail consiste à analyser les tests unitaires existants, à évaluer les tests générés automatiquement et à utiliser les tests de mutation pour identifier des comportements insuffisamment vérifiés.

---

# Partie 1 — Analyse de mutation avec PIT (Pitest)

## 1. Objectif

Nous avons utilisé PIT (Pitest) afin d'évaluer la qualité des tests unitaires de la classe `EmbeddedDocumentUtil`.

PIT introduit automatiquement de petites modifications dans le code source, appelées **mutants**, puis exécute les tests afin de vérifier si ces modifications sont détectées.

Les résultats principaux sont :

- **KILLED** : un test échoue à cause de la mutation. Le mutant est détecté.
- **SURVIVED** : aucun test ne détecte la modification introduite.
- **NO_COVERAGE** : aucun test sélectionné n'exécute le code contenant la mutation.

Notre démarche comprend trois étapes :

1. Exécuter PIT avec les tests originaux.
2. Comparer les résultats après l'ajout des tests générés automatiquement.
3. Analyser le mutant survivant, ajouter un test manuel et exécuter PIT de nouveau.

## 2. Classe sélectionnée et justification

La classe analysée est :

`org.apache.tika.extractor.EmbeddedDocumentUtil`

Fichier source :

`tika-core/src/main/java/org/apache/tika/extractor/EmbeddedDocumentUtil.java`

Fichier contenant les tests originaux :

`tika-core/src/test/java/org/apache/tika/extractor/EmbeddedDocumentUtilExtensionTest.java`

Cette classe contient des méthodes utilitaires liées au traitement des documents intégrés, notamment la normalisation des types MIME, la génération de noms de ressources et la récupération d'extracteurs.

Elle possédait déjà des tests unitaires, mais sa couverture était incomplète.

### Couverture initiale

| Mesure | Résultat |
|---|---|
| Instructions | 123 / 378 (32,5 %) |
| Branches | 15 / 62 (24,2 %) |
| Lignes | 32 / 107 (29,9 %) |
| Méthodes | 9 / 22 (40,9 %) |

La classe respectait donc les critères de sélection : elle possédait déjà des tests, n'était pas couverte à 100 % et contenait un mutant survivant identifié par PIT.

## 3. Configuration de PIT

Nous avons intégré PIT dans le fichier `tika-core/pom.xml`.

La configuration utilisée est :

```xml
<!-- Mutation testing with PIT -->
<plugin>
  <groupId>org.pitest</groupId>
  <artifactId>pitest-maven</artifactId>
  <version>1.22.0</version>

  <dependencies>
    <dependency>
      <groupId>org.pitest</groupId>
      <artifactId>pitest-junit5-plugin</artifactId>
      <version>1.2.3</version>
    </dependency>
  </dependencies>

  <configuration>
    <targetClasses>
      <param>org.apache.tika.extractor.EmbeddedDocumentUtil</param>
    </targetClasses>

    <targetTests>
      <param>org.apache.tika.extractor.EmbeddedDocumentUtilExtensionTest</param>
      <param>org.apache.tika.extractor.EmbeddedDocumentUtil_normalizeMediaType_*</param>
    </targetTests>
  </configuration>
</plugin>
```

Le paramètre `targetClasses` indique la classe dans laquelle PIT doit générer des mutations.

Le paramètre `targetTests` indique les classes de tests utilisées pour détecter ces mutations.

Nous avons initialement sélectionné uniquement `EmbeddedDocumentUtilExtensionTest`, puis ajouté la classe de tests générée automatiquement pour comparer les résultats.

La dépendance `pitest-junit5-plugin` permet d'utiliser PIT avec JUnit 5.

### Commande d'exécution

Depuis la racine du dépôt, sous Windows :

```powershell
.\mvnw.cmd -pl tika-core org.pitest:pitest-maven:mutationCoverage
```

Les rapports HTML sont générés dans :

`tika-core/target/pit-reports/`

Ces rapports permettent d'identifier les mutants tués, survivants et non couverts, ainsi que les méthodes concernées.

## 4. Première analyse : tests originaux

Nous avons d'abord exécuté PIT avec uniquement les tests existants de `EmbeddedDocumentUtilExtensionTest`.

Cette première exécution nous a permis d'établir une référence avant l'ajout des nouveaux tests.

### Résultats initiaux

| Indicateur | Résultat |
|---|---:|
| Mutants générés | 73 |
| Mutants tués | 21 |
| Mutants survivants | 1 |
| Mutants sans couverture | 51 |
| Mutation score | 29 % |
| Test strength | 95 % |
| Couverture des lignes | 32 / 107 (30 %) |

Sur les 73 mutants générés, 21 ont été détectés, un a survécu et 51 n'étaient pas couverts.

Le **mutation score de 29 %** représente la proportion des mutants générés qui ont été tués.

Le **test strength de 95 %** représente la proportion des mutants tués parmi les mutants effectivement couverts, soit 21 mutants sur 22.

Ces résultats montrent que les tests existants détectaient déjà la majorité des mutations dans les portions de code qu'ils exécutaient.

Cependant, la présence d'un mutant survivant indiquait qu'un comportement n'était pas suffisamment vérifié.

## 5. Deuxième analyse : ajout des tests générés

Nous avons ensuite ajouté la classe de tests générée automatiquement à la configuration de PIT.

L'objectif était de déterminer si ces tests permettaient de détecter des mutations supplémentaires.

### Comparaison

| Indicateur | Tests originaux | Originaux + tests générés |
|---|---:|---:|
| Mutants générés | 73 | 73 |
| Mutants tués | 21 | 21 |
| Mutants survivants | 1 | 1 |
| Mutants sans couverture | 51 | 51 |
| Mutation score | 29 % | 29 % |
| Test strength | 95 % | 95 % |
| Couverture des lignes | 30 % | 30 % |

PIT a confirmé que les deux classes de tests avaient été prises en compte.

Cependant, aucun mutant supplémentaire n'a été éliminé.

Le test généré vérifiait principalement le comportement de la méthode `normalizeMediaType`.

Or, les tests originaux exerçaient déjà indirectement une partie de cette logique, notamment avec `testOcrRoutingTypeIsNormalized`, qui vérifie la résolution de l'extension `.png` à partir du type MIME `image/ocr-png`.

Ainsi, le nouveau test était fonctionnel, mais il n'a pas amélioré la capacité de détection des mutants dans cette analyse.

Ce résultat montre qu'un test supplémentaire peut être valide sans nécessairement augmenter le score de mutation.

## 6. Identification du mutant survivant

Après les deux premières analyses, nous avons consulté le rapport HTML de PIT afin d'identifier le mutant survivant.

Celui-ci se trouvait dans la méthode :

`getEmbeddedDocumentExtractor(ParseContext context)`

### Code original

```java
EmbeddedDocumentExtractor extractor =
        context.get(EmbeddedDocumentExtractor.class);

if (extractor != null) {
    return extractor;
}
```

Cette méthode vérifie si un extracteur existe déjà dans le `ParseContext`.

Lorsqu'un extracteur est présent, le comportement attendu consiste à retourner directement cette même instance.

### Mutation introduite par PIT

Le mutateur utilisé était :

`NegateConditionals`

Ce mutateur inverse une condition logique.

Condition originale :

```java
if (extractor != null)
```

Condition mutée, conceptuellement :

```java
if (extractor == null)
```

**Statut initial : SURVIVED**

### Pourquoi cette mutation est importante

Avec le code original, lorsqu'un extracteur existe déjà, la méthode retourne immédiatement cet objet.

Avec la condition inversée, la méthode ne retourne plus directement l'extracteur existant et poursuit son exécution vers la création d'un nouvel extracteur.

Ce changement peut entraîner la perte de la configuration initialement enregistrée dans le contexte.

### Pourquoi le mutant survivait-il ?

Les tests sélectionnés ne vérifiaient pas explicitement que la méthode retournait exactement la même instance lorsqu'un extracteur existait déjà.

La condition pouvait donc être inversée sans provoquer d'échec dans les tests.

Nous avons identifié une faiblesse dans les assertions existantes et décidé d'ajouter un test manuel ciblant directement ce comportement.

## 7. Test manuel ajouté

Nous avons ajouté un nouveau test dans :

`tika-core/src/test/java/org/apache/tika/extractor/EmbeddedDocumentUtilExtensionTest.java`

### Nom du test

`testExistingEmbeddedDocumentExtractorIsReturned`

### Code du test

```java
@Test
public void testExistingEmbeddedDocumentExtractorIsReturned() {
    ParseContext context = new ParseContext();

    EmbeddedDocumentExtractor expected =
            new ParsingEmbeddedDocumentExtractor(context);

    context.set(EmbeddedDocumentExtractor.class, expected);

    EmbeddedDocumentExtractor actual =
            EmbeddedDocumentUtil.getEmbeddedDocumentExtractor(context);

    assertSame(expected, actual);
}
```

Nous avons également ajouté l'import :

```java
import static org.junit.jupiter.api.Assertions.assertSame;
```

### Intention du test

Ce test vérifie que `getEmbeddedDocumentExtractor` retourne l'extracteur déjà enregistré dans le contexte plutôt que de créer une nouvelle instance.

Il cible directement le comportement affecté par le mutant survivant.

### Choix des données

Nous créons un `ParseContext` et une instance de `ParsingEmbeddedDocumentExtractor`.

Nous enregistrons ensuite cette instance dans le contexte :

```java
context.set(EmbeddedDocumentExtractor.class, expected);
```

Ces données permettent de reproduire précisément le cas où un extracteur existe déjà.

Le choix est directement motivé par la mutation identifiée dans le rapport PIT.

### Oracle du test

L'oracle utilisé est :

```java
assertSame(expected, actual);
```

L'assertion `assertSame` vérifie que les deux références correspondent exactement au même objet.

Cette vérification est plus précise qu'une assertion `assertNotNull`, car une nouvelle instance pourrait être non nulle tout en violant le comportement attendu.

Avec le code original, le test réussit puisque l'extracteur existant est retourné.

Avec le mutant, la condition est inversée et la méthode crée un nouvel extracteur. L'assertion échoue donc.

Le test permet ainsi de détecter directement le mutant ciblé.

### Validation du test

Commande utilisée :

```powershell
.\mvnw.cmd -pl tika-core -Dtest=EmbeddedDocumentUtilExtensionTest test
```

Résultat :

| Indicateur | Résultat |
|---|---:|
| Tests exécutés | 11 |
| Échecs | 0 |
| Erreurs | 0 |
| Tests ignorés | 0 |
| Résultat Maven | BUILD SUCCESS |

Le fichier contenait initialement 10 tests.

Après l'ajout de notre test manuel, les 11 tests ont réussi.

## 8. Troisième analyse : résultats après le test manuel

Nous avons relancé PIT après l'ajout du test manuel afin de mesurer son effet.

### Résultats

| Indicateur | Avant | Après |
|---|---:|---:|
| Mutants générés | 73 | 73 |
| Mutants tués | 21 | 23 |
| Mutants survivants | 1 | 0 |
| Mutants sans couverture | 51 | 50 |
| Mutation score | 29 % | 32 % |
| Test strength | 95 % | 100 % |
| Couverture des lignes | 32 / 107 (30 %) | 33 / 107 (31 %) |

Le test manuel a permis d'éliminer le mutant survivant.

Le nombre total de mutants tués est également passé de 21 à 23.

### Mutant `NegateConditionals`

Avant l'ajout du test, 10 mutants de ce type étaient tués et un survivait.

Après l'ajout du test, 11 mutants de ce type étaient tués et aucun ne survivait.

L'assertion `assertSame` permet de détecter l'inversion de la condition `extractor != null`.

### Mutant `NullReturn`

Le nombre de mutants tués par `NullReturn` est passé de 3 à 4.

Ce mutateur remplace une valeur retournée par `null`.

Notre test exige que la méthode retourne précisément l'objet `expected`.

Si PIT remplace ce retour par `null`, l'assertion `assertSame(expected, actual)` échoue.

Ainsi, le test manuel a permis de détecter deux mutations supplémentaires.

### Interprétation des résultats

Le mutation score est passé de 29 % à 32 %, soit une amélioration de trois points de pourcentage.

Le test strength est passé de 95 % à 100 %.

Cela signifie que tous les mutants effectivement couverts par les tests sélectionnés ont été éliminés.

Il faut toutefois distinguer **100 % de test strength** et **100 % de mutation score**.

Notre mutation score reste à 32 %, puisque 50 mutants demeurent sans couverture.

Ces mutants ne sont pas considérés comme survivants : les tests sélectionnés n'exécutent simplement pas les portions de code correspondantes.

## 9. Synthèse des trois analyses

| Étape | Mutants tués | Survivants | Sans couverture | Mutation score | Test strength |
|---|---:|---:|---:|---:|---:|
| Tests originaux | 21 | 1 | 51 | 29 % | 95 % |
| Originaux + tests générés | 21 | 1 | 51 | 29 % | 95 % |
| Après le test manuel | 23 | 0 | 50 | 32 % | 100 % |

Les résultats montrent que l'ajout des tests générés n'a pas amélioré le score de mutation dans notre cas.

En revanche, l'analyse du rapport PIT a permis d'identifier une faiblesse précise dans les tests existants.

Le test manuel `testExistingEmbeddedDocumentExtractorIsReturned` a éliminé le mutant survivant de type `NegateConditionals` et a également détecté un mutant supplémentaire de type `NullReturn`.

## 10. Conclusion

L'utilisation de PIT a permis d'identifier un comportement insuffisamment vérifié dans la méthode `getEmbeddedDocumentExtractor`.

Le mutant survivant inversait une condition logique, ce qui pouvait empêcher la méthode de retourner un extracteur déjà enregistré dans le contexte.

Nous avons ajouté un test manuel utilisant `assertSame` pour vérifier l'identité de l'objet retourné.

Après cette modification :

- Le nombre de mutants tués est passé de 21 à 23.
- Le nombre de mutants survivants est passé de 1 à 0.
- Le mutation score est passé de 29 % à 32 %.
- Le test strength est passé de 95 % à 100 %.

Cette expérience montre que les tests de mutation permettent de détecter des faiblesses que les mesures traditionnelles de couverture ne révèlent pas nécessairement.

---

# Partie 2 — ChatUniTest

> **Ta partie.**

## 1. Installation et configuration de ChatUniTest

*À compléter.*

## 2. Sélection des méthodes et génération automatique des tests

*À compléter.*

## 3. Description des tests générés

*À compléter.*

## 4. Compilation, exécution et corrections nécessaires

*À compléter.*

## 5. Comparaison qualitative des oracles avec les tests originaux

*À compléter.*

