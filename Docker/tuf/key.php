#!/usr/bin/php8.2
<?php
/**
 * Tested with PHP 8.2
 *
 * This script allows to manage the metadata/keys.json database
 */

// Set defaults
$scriptRoot = __DIR__;
$keysJson = '/go/metadata/keys.json';
$tryRun = false;
$task = 'list';

$script = array_shift($argv);

if (empty($argv)) {
    echo <<<TEXT
        Joomla! Update Key Database Update script
        =========================================
        Usage:
          php {$script} <cmd> [--options]

        Description:
          Add, Removes, Lists keys for joomla tuf update environment
            
          <cmd>
            add: Add a key
            remove: Removes key
            list: List keys

          <options>
            --try-run:
              In case of modification outputs the new state without writing it
            --name:
              The name of the key owner
            --public:
              The public key
            --expires:
              Days
            --keyid:
              The keyid in the tuf database
            --role:
              root, targets, snapshot, timestamp

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
                $baseBranches = $argi[1];
                break;
            case '--public':
                $targetBranch = $argi[1];
                break;
            case '--expires':
                $prNumber = $argi[1];
                break;
            case '--keyid':
                $label = $argi[1];
                break;
            case '--role':
                $additionalReason = $argi[1];
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
            default:
                die('Unknown option: ' . $argi[0]);
        }
    }
}

if (!file_exists($keysJson)) {
    file_put_contents($keysJson, '{}');
}

$storage = json_decode(file_get_contents($keysJson), true, 512, JSON_THROW_ON_ERROR);

var_dump($storage);