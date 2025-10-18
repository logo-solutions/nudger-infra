# 🧩 MySQL — Réinitialisation de l’utilisateur `xwiki`

## 🎯 Objectif
Lors d’un déploiement manuel de MySQL dans le namespace `xwiki`, il est possible que le compte `xwiki@'%'` n’ait pas encore les privilèges nécessaires pour permettre la connexion depuis le pod XWiki.

Ce guide décrit la procédure manuelle pour **(re)créer le compte MySQL `xwiki`** et **forcer le flush des privilèges**.

---

## ⚙️ Étapes détaillées

### 1️⃣ Ouvrir un shell dans le pod MySQL
```bash
kubectl exec -n xwiki -it mysql-0 -- bash
```

### 2️⃣ Entrer dans le client MySQL
```bash
mysql -u root
```

> 💡 Si un mot de passe est défini pour `root`, ajoute `-p` :
> ```bash
> mysql -u root -p
> ```

### 3️⃣ Créer le compte et accorder les privilèges
```sql
CREATE USER 'xwiki'@'%' IDENTIFIED BY 'xwiki';
GRANT ALL PRIVILEGES ON *.* TO 'xwiki'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

### 4️⃣ Vérifier les utilisateurs existants
```sql
SELECT Host, User FROM mysql.user;
```

### 5️⃣ Quitter MySQL
```sql
exit;
```

### 6️⃣ Vérifier la connectivité depuis XWiki
Exécuter depuis le pod XWiki :
```bash
kubectl exec -n xwiki -it deploy/xwiki --   bash -c "mysql -h mysql -u xwiki -pxwiki -e 'SHOW DATABASES;'"
```

✅ Si la configuration est correcte, la sortie devrait être :
```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| xwiki              |
+--------------------+
```

---

## 💾 Notes complémentaires
- Le script d’initialisation `initdbScripts` du chart Helm XWiki ne s’exécute **que lors du premier déploiement d’un volume MySQL neuf**.  
- En cas de re-déploiement, les volumes persistants gardent les données et utilisateurs : il faut donc forcer un `CREATE USER` manuel ou purger le PVC associé à MySQL.

