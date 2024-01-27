#!/usr/bin/php8.2
<?php
/**
 * Tested with PHP 8.2
 *
 * This script allows to manage the metadata/keys.json database
 */

// Set defaults
$scriptRoot = __DIR__;
$keysJson = '/go/metadata/keyStorage.json';
$tryRun = false;
$task = 'list';
$format= "role keyId publicKey name\n";

function output($text)
{
    echo $text . "\n";
}

$script = array_shift($argv);

if (empty($argv)) {
    echo <<<TEXT
        Joomla! Update Key Database Update script
        =========================================
        Usage:
          php {$script} <cmd> [--options]

        Description:
          Add, Removes and search for keys for joomla tuf update environment
            
          <cmd>
            add: Add a key (all options entry relevant options are needed)
            remove: Removes key (only keyId is supported case sensetive)
            list: List keys (options are case insensitiv)
            get: Returns one entry (only keyId is supported case sensetive)

          <options>
            --try-run:
              In case of modification outputs the new state without writing it
            --name:
              The name of the key owner
            --public-key:
              The public key
            --keyId:
              The keyid in the tuf database
            --role:
              root, targets, snapshot, timestamp
            --format:
              json or string with placeholders: name, publicKey, keyId, role 

        TEXT;
    die(1);
}

foreach ($argv as $arg) {
    if (substr($arg, 0, 2) === '--') {
        $argi = explode('=', $arg, 2);
        switch ($argi[0]) {
            case '--try-run':
                $tryRun = true;
                break;
            case '--name':
                $name = $argi[1];
                if (!preg_match('/^[a-zA-Z0-9_ ]+$/', $name)) {
                    output('Name has is invalid characters!');
                    die();
                }
                break;
            case '--public-key':
                $publicKey = $argi[1];
                if (!preg_match('/^[a-z0-9]+$/', $publicKey)) {
                    output('Public key is invalid!');
                    die();
                }
                break;
            case '--keyId':
                $keyId = $argi[1];
                if (!preg_match('/^[a-z0-9]+$/', $keyId)) {
                    output('Key Id is invalid!');
                    die();
                }
                break;
            case '--role':
                $role = $argi[1];
                if (!in_array($role, ['root', 'snapshot', 'targets', 'timestamp', 'mirror'])) {
                    output('Role is invalid!');
                    die();
                }
                break;
            case '--format':
                $format = $argi[1];
                break;
            default:
                die('Unknown option: ' . $argi[0]);
        }
    } else {
        switch ($arg) {
            case 'add':
                $task = 'add';
                break;
            case 'remove':
                $task = 'remove';
                break;
            case 'list':
                $task = 'list';
                break;
            case 'get':
                $task = 'get';
                break;
            default:
                die('Unknown option: ' . $argi[0]);
        }
    }
}

function saveDatabase($data)
{
    global $keysJson, $tryRun;

    $json = json_encode($data, JSON_PRETTY_PRINT);

    if ($tryRun) {
        output("Try Run not saving database");
        output("--- Start ---");
        output($json);
        output("--- End ---");
        return;
    }
    try {
        file_put_contents($keysJson, $json);
    } catch (\Throwable $e) {
        output('Unable to save Database: ' . $e->getMessage());
        die(1);
    }
}

function loadDatabase()
{
    global $keysJson;

    try {
        return json_decode(file_get_contents($keysJson), true, 512, JSON_THROW_ON_ERROR);
    } catch (\Throwable $e) {
        output('Unable to save Database: ' . $e->getMessage());
        die(1);
    }
}

function renderList($data)
{
    global $format;

    if (strtolower($format) === 'json') {
        echo json_encode($data);
        return;
    }

    // detect sindle entry by detecting keyId as named key
    if (!empty($data['keyId'])) {
        $data = [$data];
    }

    foreach($data as $row) {
        $row['role'] = implode(',', $row['role']);
        echo str_replace('\n', "\n", str_replace(array_keys($row), array_values($row), $format));
    }
}

if (!file_exists($keysJson)) {
    file_put_contents($keysJson, '{}');
}

$storage = loadDatabase();

switch ($task) {
    case 'add':
        if (!isset($name, $publicKey, $keyId, $role)) {
            output('Parameters missing');
            die(1);
        }

        if (!empty($storage[$keyId])) {
            if (in_array($role, $storage[$keyId]['role'])) {
                output('Key already exists');
                die(1);
            }

            $storage[$keyId]['role'][] = $role;
        } else {
            $storage[$keyId] = [
                'keyId' => $keyId,
                'name' => $name,
                'role' => [$role],
                'publicKey' => $publicKey,
            ];
        }

        saveDatabase($storage);

        break;
    case 'remove':
        if (!isset($keyId)) {
            output('Parameters missing');
            die(1);
        }

        if (empty($storage[$keyId])) {
            output('Key does not exists');
            die(1);
        }

        if (isset($role)) {
            foreach ($storage[$keyId]['role'] as $k => $v) {
                if (stripos($v, $role) !== false) {
                    unset($storage[$keyId]['role'][$k]);
                }
            }
            if (empty($storage[$keyId]['role'])) {
                unset($storage[$keyId]);
            }
        } else {
            unset($storage[$keyId]);
        }

        saveDatabase($storage);

        break;
    case 'list':
        $tmpStorage = $storage;

        foreach ($tmpStorage as $k => $v) {
            if (isset($name) && stripos($v['name'], $name) === false) {
                unset($tmpStorage[$k]);
            }
            if (isset($publicKey) && stripos($v['publicKey'], $publicKey) === false) {
                unset($tmpStorage[$k]);
            }
            if (isset($keyId) && stripos($v['keyId'], $keyId) === false) {
                unset($tmpStorage[$k]);
            }
            if (isset($role) && stripos($v['role'], $role) === false) {
                unset($tmpStorage[$k]);
            }
        }

        renderList($tmpStorage);

        break;
    case 'get':
        if (!isset($keyId)) {
            output('Parameters missing');
            die(1);
        }

        if (empty($storage[$keyId])) {
            output('Key does not exists');
            die(1);
        }
        $v = $storage[$keyId];

        renderList($v);

        break;
}
