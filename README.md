
# IFT3913 — Tâche 3 : Analyse des vulnérabilités avec Semgrep

## 1. Modification du workflow GitHub Actions

### 1.1 Objectif

Pour cette partie de la tâche 3, nous devions modifier le workflow GitHub Actions de Tika pour que le processus de build échoue lorsqu'un commit introduit une nouvelle vulnérabilité détectée par Semgrep.

L'objectif était donc de ne pas seulement détecter les vulnérabilités présentes dans le code, mais aussi de comparer les résultats avant et après les modifications.

Le workflow modifié se trouve dans le fichier :

`.github/workflows/semgrep-vulnerability-analysis.yml`

### 1.2 Modifications apportées

Un premier workflow GitHub Actions avait déjà été créé. Il permettait d'installer Semgrep et de lancer une analyse sur un fichier Java de Tika avec la configuration `p/default`.

Cependant, cette première version ne comparait pas les vulnérabilités présentes avant et après un commit. Elle utilisait également une variable `EXIT_CODE` pour essayer de provoquer un échec, mais cette variable n'était pas transmise correctement entre les étapes du workflow.

Nous avons donc modifié le workflow pour ajouter les fonctionnalités suivantes :

- Déclenchement automatique lors d'une pull request vers `main` ou `dev`.
- Installation de Python 3.12 et de Semgrep 1.185.0.
- Récupération de la version de référence du code avec Git.
- Analyse du fichier `EmbeddedDocumentUtil.java` avant et après les modifications.
- Génération de deux rapports Semgrep au format JSON.
- Comparaison des résultats afin d'identifier les nouvelles vulnérabilités.
- Échec automatique du workflow lorsqu'au moins une nouvelle vulnérabilité est détectée.

Le workflow peut également être exécuté manuellement avec `workflow_dispatch`.

### 1.3 Choix des règles Semgrep

Au départ, nous avons utilisé la configuration `p/java`, qui exécutait 60 règles Java dans notre environnement.

Cependant, après avoir introduit les vulnérabilités, seulement trois étaient détectées.

Nous avons aussi essayé les configurations `p/security-audit` et `p/owasp-top-ten`, mais elles ne détectaient pas les quatre autres vulnérabilités.

Nous avons donc décidé de conserver `p/java` et d'ajouter quatre règles officielles supplémentaires :

- `object-deserialization`
- `xmlinputfactory-external-entities-enabled`
- `overly-permissive-file-permission`
- `command-injection-formatted-runtime-call`

Nous n'avons pas créé de règles personnalisées. Toutes les règles utilisées proviennent de Semgrep.

Avec cette configuration, nous avons exécuté 64 règles, ce qui nous a permis de détecter les 7 vulnérabilités introduites dans notre classe.

### 1.4 Comparaison des rapports

Pour savoir si une vulnérabilité est nouvelle, le workflow analyse deux versions du fichier Java.

La première version correspond au code de référence, avant les modifications. La deuxième correspond au code présent dans la pull request.

Les résultats sont enregistrés dans deux fichiers :

- `avant.json`
- `apres.json`

Nous avons utilisé un script Python directement dans le workflow pour comparer les deux rapports.

Le script récupère les détections Semgrep et les compare selon l'identifiant de la règle, le chemin du fichier et le code signalé.

Nous avons choisi cette méthode plutôt qu'une comparaison des numéros de ligne, car les lignes peuvent changer lorsqu'on ajoute ou supprime du code.

Si une nouvelle détection apparaît dans le rapport après les modifications, le script termine avec `sys.exit(1)`, ce qui provoque l'échec du job GitHub Actions.

Si aucune nouvelle vulnérabilité n'est détectée, le script termine normalement.

Cette comparaison est adaptée à notre cas d'étude, mais elle a certaines limites. Par exemple, une modification du code signalé pourrait être considérée comme une nouvelle détection même si le problème existait déjà.

### 1.5 Validation du workflow

Pour valider notre modification, nous avons d'abord effectué les analyses Semgrep localement.

Nous avons analysé la version originale de `EmbeddedDocumentUtil.java`, puis la version contenant les sept vulnérabilités introduites.

Les résultats obtenus étaient les suivants :

| Analyse | Vulnérabilités détectées |
|---|---|
| Avant les modifications | 0 |
| Après les modifications | 7 |
| Nouvelles vulnérabilités | 7 |

Après cette vérification locale, nous avons créé une branche `tache3-semgrep` contenant les modifications du code Java ainsi que le nouveau workflow.

Nous avons ensuite créé une pull request vers la branche `main` de notre fork Tika pour tester l'exécution de GitHub Actions.

Lors de l'exécution, le workflow a produit les résultats suivants :

```text
Vulnerabilites avant : 0
Vulnerabilites apres : 7
Nouvelles vulnerabilites : 7

ECHEC : nouvelles vulnerabilites detectees.
Process completed with exit code 1.
```

Le workflow a donc échoué à l'étape de comparaison des vulnérabilités, comme prévu.

Cet échec est volontaire et montre que le workflow est capable de bloquer une pull request qui introduit de nouvelles vulnérabilités détectées par Semgrep.

Les rapports JSON sont également configurés pour être publiés comme artifacts dans GitHub Actions, ce qui permet de consulter les résultats des analyses.

### 1.6 Limites

Notre workflow analyse actuellement uniquement la classe `EmbeddedDocumentUtil.java`, puisque c'est dans cette classe que nous avons introduit les vulnérabilités pour la tâche 3.

Il pourrait être amélioré pour analyser l'ensemble des classes Java de Tika.

De plus, nous avons validé le scénario où sept nouvelles vulnérabilités sont introduites. Le scénario où aucune nouvelle vulnérabilité n'est ajoutée n'a pas encore été testé directement dans GitHub Actions.

### 1.7 Conclusion

La modification du workflow GitHub Actions nous a permis d'automatiser la détection des nouvelles vulnérabilités dans notre cas d'étude.

La principale amélioration par rapport à la première version est l'ajout d'une comparaison entre les résultats Semgrep avant et après les modifications.

Nous avons réussi à détecter les sept vulnérabilités introduites et à faire échouer automatiquement le workflow lors de notre test sur GitHub.

Cette validation montre que le mécanisme fonctionne pour le scénario testé et permet de mieux contrôler l'introduction de nouvelles vulnérabilités dans le code.

---

## 2. Introduction des vulnérabilités dans Apache Tika

### 2.1 Objectif et choix du fichier

Pour cette partie de la tâche 3, nous devions modifier le code de notre cas d'étude Apache Tika afin d'introduire 7 vulnérabilités de types différents pouvant être détectées par Semgrep.

Nous avons choisi de modifier la classe suivante :

`tika-core/src/main/java/org/apache/tika/extractor/EmbeddedDocumentUtil.java`

Nous avons choisi cette classe parce que nous avions déjà travaillé dessus pendant la tâche 2, notamment pour les tests unitaires et les tests de mutation. Nous connaissions donc déjà sa structure et certaines de ses fonctionnalités.

Cette classe sert principalement à gérer les documents intégrés dans Tika, notamment la détection des types de fichiers, les métadonnées et la récupération des parseurs.

Nous avons ajouté les vulnérabilités dans des méthodes séparées à la fin de la classe. Cela nous permettait de les identifier facilement et de ne pas modifier directement les méthodes existantes.

Les méthodes vulnérables ont été ajoutées uniquement pour la tâche et ne sont pas appelées par le fonctionnement normal de Tika.

### 2.2 Vulnérabilité 1 — Algorithme cryptographique faible (MD5)

**Type :** Utilisation d'un algorithme cryptographique faible  
**CWE :** CWE-327  
**Règle Semgrep :** `java.lang.security.audit.crypto.use-of-md5.use-of-md5`  
**Ligne détectée :** 401

**Code introduit :**

```java
private static byte[] vulnerableHash(String password)
        throws java.security.NoSuchAlgorithmException {

    MessageDigest digest = MessageDigest.getInstance("MD5");

    return digest.digest(
            password.getBytes(java.nio.charset.StandardCharsets.UTF_8));
}
```

**Explication :**

Cette méthode utilise l'algorithme MD5 pour calculer une empreinte à partir d'un mot de passe.

Le problème est que MD5 est un algorithme ancien qui présente plusieurs faiblesses, notamment au niveau de sa résistance aux collisions. Il n'est donc plus recommandé pour les utilisations cryptographiques sensibles.

Dans notre cas, nous avons volontairement utilisé `MessageDigest.getInstance("MD5")` pour introduire cette mauvaise pratique.

Pour le stockage des mots de passe, MD5 est également inadapté, car il est trop rapide et ne fournit pas à lui seul un mécanisme de hachage sécurisé avec sel.

**Résultat Semgrep :**

Semgrep a détecté l'utilisation de MD5 avec la règle `use-of-md5` et a signalé une vulnérabilité bloquante à la ligne 401.

### 2.3 Vulnérabilité 2 — Injection de commandes

**Type :** OS Command Injection  
**CWE :** CWE-78  
**Règle Semgrep :** `command-injection-formatted-runtime-call`  
**Ligne détectée :** 422

**Code introduit :**

```java
private static void vulnerableCommandExecution(String command)
        throws IOException {

    java.lang.Runtime runtime = java.lang.Runtime.getRuntime();

    runtime.exec("cmd.exe /c " + command);
}
```

**Explication :**

Cette méthode permet d'exécuter une commande système à partir d'une chaîne de caractères reçue en paramètre.

Le problème vient du fait que la variable `command` est directement ajoutée à la commande exécutée, sans aucune validation.

Si cette valeur est contrôlée par un utilisateur malveillant, celui-ci pourrait influencer l'exécution de commandes non autorisées sur le système.

Nous avons introduit cette vulnérabilité pour montrer le danger de construire une commande système avec une entrée non fiable.

**Résultat Semgrep :**

Au départ, notre première version n'était pas détectée. Nous avons donc modifié la méthode pour utiliser une variable de type `Runtime` et une concaténation directe.

Après cette modification, Semgrep a détecté la vulnérabilité à la ligne 422 avec la règle `command-injection-formatted-runtime-call`.

### 2.4 Vulnérabilité 3 — Injection SQL

**Type :** SQL Injection  
**CWE :** CWE-89  
**Règle Semgrep :** `java.lang.security.audit.formatted-sql-string.formatted-sql-string`  
**Ligne détectée :** 445

**Code introduit :**

```java
public static void vulnerableSqlQuery(
        Connection connection, String username)
        throws SQLException {

    String query = "SELECT * FROM users WHERE username = '"
            + username + "'";

    Statement statement = connection.createStatement();

    statement.executeQuery(query);
}
```

**Explication :**

Cette méthode construit une requête SQL en ajoutant directement la variable `username` à la requête.

Le problème est que cette variable n'est pas validée et que la requête est exécutée avec `Statement`.

Si un utilisateur malveillant contrôle `username`, il pourrait modifier le fonctionnement de la requête SQL.

Pour éviter ce problème, il serait préférable d'utiliser un `PreparedStatement` avec des paramètres.

**Résultat Semgrep :**

Semgrep a détecté l'injection SQL à la ligne 445 avec la règle `formatted-sql-string`.

### 2.5 Vulnérabilité 4 — XML External Entity (XXE)

**Type :** XML External Entity  
**CWE :** CWE-611  
**Règle Semgrep :** `xmlinputfactory-external-entities-enabled`  
**Ligne détectée :** 462

**Code introduit :**

```java
private static XMLInputFactory vulnerableXmlParsing() {

    XMLInputFactory factory = XMLInputFactory.newInstance();

    factory.setProperty(
            XMLInputFactory.IS_SUPPORTING_EXTERNAL_ENTITIES,
            true);

    return factory;
}
```

**Explication :**

Cette méthode crée une fabrique de parseurs XML et active explicitement le support des entités externes.

Le problème est que ces entités peuvent permettre à un document XML de demander l'accès à des ressources externes, comme des fichiers locaux ou des ressources réseau.

Si un attaquant fournit un document XML malveillant et qu'un parseur utilisant cette configuration l'analyse, cela pourrait permettre l'accès à des données qui ne devraient pas être accessibles.

Nous avons donc volontairement activé cette option pour introduire une vulnérabilité XXE.

**Résultat Semgrep :**

Semgrep a détecté l'activation des entités externes à la ligne 462 avec la règle `xmlinputfactory-external-entities-enabled`.

### 2.6 Vulnérabilité 5 — Désérialisation non sécurisée

**Type :** Insecure Deserialization  
**CWE :** CWE-502  
**Règle Semgrep :** `object-deserialization`  
**Ligne détectée :** 482

**Code introduit :**

```java
private static Object vulnerableDeserialization(InputStream input)
        throws IOException, ClassNotFoundException {

    ObjectInputStream objectInput =
            new ObjectInputStream(input);

    return objectInput.readObject();
}
```

**Explication :**

Cette méthode utilise `ObjectInputStream` pour reconstruire un objet Java à partir d'un flux de données.

Le problème est que la désérialisation d'objets provenant de sources non fiables peut être dangereuse.

Un attaquant pourrait fournir un objet spécialement construit pour provoquer un comportement inattendu pendant la désérialisation.

La méthode ne vérifie pas les types d'objets autorisés et ne filtre pas les données reçues.

**Résultat Semgrep :**

Cette vulnérabilité n'était pas détectée avec notre configuration initiale `p/java`.

Nous avons donc ajouté la règle officielle `object-deserialization`, qui a détecté la création de `ObjectInputStream` à la ligne 482.

### 2.7 Vulnérabilité 6 — Permissions de fichiers excessives

**Type :** Overly Permissive File Permissions  
**CWE :** CWE-276  
**Règle Semgrep :** `overly-permissive-file-permission`  
**Ligne détectée :** 501

**Code introduit :**

```java
private static void vulnerableFilePermissions(Path file)
        throws IOException {

    Files.setPosixFilePermissions(
            file,
            PosixFilePermissions.fromString("rwxrwxrwx"));
}
```

**Explication :**

Cette méthode modifie les permissions d'un fichier en utilisant la valeur `rwxrwxrwx`.

Cette valeur signifie que le propriétaire, le groupe et les autres utilisateurs peuvent tous lire, modifier et exécuter le fichier.

Le problème est que ces permissions sont beaucoup trop permissives, surtout si le fichier contient des informations sensibles.

Cela pourrait permettre à des utilisateurs non autorisés de modifier ou de consulter des fichiers.

Nous avons utilisé cette configuration pour montrer une mauvaise gestion des permissions de fichiers.

**Résultat Semgrep :**

Semgrep a détecté les permissions excessives à la ligne 501 grâce à la règle officielle `overly-permissive-file-permission`.

### 2.8 Vulnérabilité 7 — Protocole SSL obsolète

**Type :** Utilisation d'un protocole SSL faible  
**CWE :** CWE-326  
**Règle Semgrep :** `java.lang.security.audit.weak-ssl-context.weak-ssl-context`  
**Ligne détectée :** 518

**Code introduit :**

```java
private static SSLContext vulnerableSslContext()
        throws java.security.NoSuchAlgorithmException {

    return SSLContext.getInstance("SSLv3");
}
```

**Explication :**

Cette méthode crée un contexte SSL utilisant la version SSLv3.

Le problème est que SSLv3 est un protocole ancien qui présente des faiblesses de sécurité connues. Il ne devrait donc plus être utilisé pour protéger les communications.

Un protocole plus récent comme TLS 1.2 ou TLS 1.3 devrait être privilégié.

Nous avons volontairement utilisé `SSLv3` pour introduire une mauvaise configuration de sécurité.

**Résultat Semgrep :**

Semgrep a détecté l'utilisation de SSLv3 à la ligne 518 avec la règle `weak-ssl-context`.

### 2.9 Comparaison des résultats Semgrep

Nous avons effectué deux analyses avec la même sélection de règles Semgrep.

La première a été effectuée sur la version du fichier avant l'introduction des vulnérabilités. La deuxième a été effectuée après les modifications.

Les résultats ont été enregistrés dans :

- `semgrep-reports/avant-final.json`
- `semgrep-reports/apres.json`

| Vulnérabilité | Avant | Après |
|---|---:|---:|
| MD5 | 0 | 1 |
| Injection de commandes | 0 | 1 |
| Injection SQL | 0 | 1 |
| XXE | 0 | 1 |
| Désérialisation non sécurisée | 0 | 1 |
| Permissions excessives | 0 | 1 |
| SSLv3 | 0 | 1 |
| **Total** | **0** | **7** |

Le rapport initial ne contenait aucune détection, tandis que le rapport final contenait 7 détections bloquantes.

Nous avons aussi confirmé ces résultats dans GitHub Actions lors d'une pull request entre la branche `tache3-semgrep` et `main`.

Le workflow a affiché :

```text
Vulnerabilites avant : 0
Vulnerabilites apres : 7
Nouvelles vulnerabilites : 7

ECHEC : nouvelles vulnerabilites detectees.
Process completed with exit code 1.
```

Ces résultats montrent que les sept vulnérabilités ont bien été introduites dans le code et détectées par Semgrep.

### 2.10 Conclusion

Pour cette partie, nous avons réussi à introduire 7 vulnérabilités de types différents dans une classe Apache Tika sur laquelle nous avions déjà travaillé pendant la tâche 2.

Nous avons utilisé les règles officielles de Semgrep pour identifier chacune d'elles. Certaines vulnérabilités ont été détectées directement avec `p/java`, tandis que d'autres ont nécessité l'ajout de règles supplémentaires.

La comparaison des rapports montre que nous sommes passés de 0 à 7 vulnérabilités détectées.

Cette partie nous a permis de mieux comprendre comment Semgrep fonctionne, mais aussi le fait qu'une vulnérabilité présente dans le code n'est pas nécessairement détectée par toutes les configurations de règles.

Les méthodes ajoutées restent des exemples de démonstration pour le cours et ne doivent pas être utilisées dans une application en production.
