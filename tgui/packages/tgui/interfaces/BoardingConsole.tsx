import { useBackend } from '../backend';
import { Box, Button, LabeledList, Section, Table } from '../components';
import { Window } from '../layouts';

interface Target {
  name: string;
  z: number;
}

interface Pod {
  ref: string;
  name: string;
  status: string;
  occupants: number;
  capacity: number;
}

interface BoardingData {
  targets: Target[];
  target_z: number;
  pods: Pod[];
  selected_pod: string | null;
  launch_delay: number; // seconds, sent from server
  launch_pending: boolean;
}

const DELAY_OPTIONS = [
  { label: 'Immediate', value: 0 },
  { label: '15 sec', value: 15 },
  { label: '30 sec', value: 30 },
  { label: '60 sec', value: 60 },
] as const;

export const BoardingConsole = () => {
  const { data, act } = useBackend<BoardingData>();
  const { targets, target_z, pods, selected_pod, launch_delay, launch_pending } = data;

  const selectedTarget = targets.find((t) => t.z === target_z) ?? null;
  const selectedPod = pods.find((p) => p.ref === selected_pod) ?? null;

  const canLaunch =
    !launch_pending && !!selectedTarget && !!selectedPod && selectedPod.status === 'Ready';

  return (
    <Window title="Boarding Control" width={440} height={620}>
      <Window.Content scrollable>

        {/* Delay selector — top of UI so it's always visible */}
        <Section title="Launch Delay">
          <Box>
            {DELAY_OPTIONS.map((opt) => (
              <Button
                key={opt.value}
                selected={launch_delay === opt.value}
                disabled={launch_pending}
                mr={1}
                onClick={() => act('set_delay', { delay: opt.value })}
              >
                {opt.label}
              </Button>
            ))}
          </Box>
        </Section>

        {/* Target Vessel */}
        <Section title="Target Vessel">
          {targets.length === 0 ? (
            <Box color="bad">No vessels on sensors.</Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Vessel</Table.Cell>
                <Table.Cell collapsing>Select</Table.Cell>
              </Table.Row>
              {targets.map((t) => (
                <Table.Row key={t.z}>
                  <Table.Cell>
                    <Box color={t.z === target_z ? 'good' : 'label'}>{t.name}</Box>
                  </Table.Cell>
                  <Table.Cell collapsing>
                    <Button
                      selected={t.z === target_z}
                      onClick={() => act('select_target', { z: t.z })}
                    >
                      {t.z === target_z ? 'Targeted' : 'Target'}
                    </Button>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>

        {/* Boarding Pods */}
        <Section title="Boarding Pods">
          {pods.length === 0 ? (
            <Box color="bad">No boarding pods on this vessel.</Box>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Pod</Table.Cell>
                <Table.Cell collapsing>Crew</Table.Cell>
                <Table.Cell collapsing>Status</Table.Cell>
                <Table.Cell collapsing>Select</Table.Cell>
              </Table.Row>
              {pods.map((p) => (
                <Table.Row key={p.ref}>
                  <Table.Cell>{p.name}</Table.Cell>
                  <Table.Cell collapsing>
                    {p.occupants}/{p.capacity}
                  </Table.Cell>
                  <Table.Cell collapsing>
                    <Box
                      color={
                        p.status === 'Ready'
                          ? 'good'
                          : p.status === 'In Transit'
                            ? 'average'
                            : 'bad'
                      }
                    >
                      {p.status}
                    </Box>
                  </Table.Cell>
                  <Table.Cell collapsing>
                    <Button
                      disabled={p.status !== 'Ready'}
                      selected={p.ref === selected_pod}
                      onClick={() => act('select_pod', { ref: p.ref })}
                    >
                      {p.ref === selected_pod ? 'Selected' : 'Select'}
                    </Button>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>

        {/* Launch */}
        <Section title="Launch">
          <LabeledList>
            <LabeledList.Item label="Target">
              {selectedTarget ? (
                <Box color="good">{selectedTarget.name}</Box>
              ) : (
                <Box color="bad">None selected</Box>
              )}
            </LabeledList.Item>
            <LabeledList.Item label="Pod">
              {selectedPod ? (
                <Box color="good">{selectedPod.name}</Box>
              ) : (
                <Box color="bad">None selected</Box>
              )}
            </LabeledList.Item>
          </LabeledList>
          <Box mt={1}>
            {launch_pending ? (
              <Box color="average" bold textAlign="center">
                LAUNCH COUNTDOWN — STAND CLEAR OF POD
              </Box>
            ) : (
              <Button
                fluid
                icon="rocket"
                color={canLaunch ? 'bad' : 'grey'}
                disabled={!canLaunch}
                onClick={() => act('launch')}
              >
                {canLaunch
                  ? `Launch Pod (${launch_delay > 0 ? `${launch_delay}s delay` : 'Immediate'})`
                  : 'Launch Pod'}
              </Button>
            )}
          </Box>
        </Section>

      </Window.Content>
    </Window>
  );
};

export default BoardingConsole;
