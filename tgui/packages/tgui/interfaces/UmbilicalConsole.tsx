import { useBackend } from '../backend';
import { Box, Button, LabeledList, Section } from '../components';
import { Window } from '../layouts';

interface UmbilicalData {
  extended: boolean;
  adjacent_ship: string | null;
  local_hatch: boolean;
  remote_hatch: boolean;
  debug_local_z: number;
  debug_link_id: string;
}

export const UmbilicalConsole = () => {
  const { data, act } = useBackend<UmbilicalData>();
  const {
    extended,
    adjacent_ship,
    local_hatch,
    remote_hatch,
    debug_local_z,
    debug_link_id,
  } = data;

  const can_extend = !extended && !!adjacent_ship && local_hatch && remote_hatch;

  return (
    <Window title="Umbilical Control" width={300} height={270}>
      <Window.Content>
        <Section title="Status">
          <LabeledList>
            <LabeledList.Item label="Umbilical">
              <Box color={extended ? 'good' : 'average'}>
                {extended ? 'Extended' : 'Retracted'}
              </Box>
            </LabeledList.Item>
            <LabeledList.Item label="Adjacent Ship">
              {adjacent_ship ? (
                adjacent_ship
              ) : (
                <Box color="bad">None detected</Box>
              )}
            </LabeledList.Item>
            <LabeledList.Item label="Local Hatch">
              <Box color={local_hatch ? 'good' : 'bad'}>
                {local_hatch ? 'Ready' : 'Not found'}
              </Box>
            </LabeledList.Item>
            <LabeledList.Item label="Remote Hatch">
              <Box color={remote_hatch ? 'good' : 'bad'}>
                {remote_hatch ? 'Ready' : 'Not found'}
              </Box>
            </LabeledList.Item>
            <LabeledList.Item label="Debug (Console)">
              z={debug_local_z} id=&quot;{debug_link_id}&quot;
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section>
          {!extended ? (
            <Button
              fluid
              icon="link"
              color={can_extend ? 'green' : 'grey'}
              disabled={!can_extend}
              onClick={() => act('extend')}
            >
              Extend Umbilical
            </Button>
          ) : (
            <Button
              fluid
              icon="unlink"
              color="bad"
              onClick={() => act('retract')}
            >
              Retract Umbilical
            </Button>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

export default UmbilicalConsole;
