import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import CompatibilityLevelInfoModal from './CompatibilityLevelInfoModal';

describe('CompatibilityLevelInfoModal', () => {
  afterEach(() => {
    jest.resetAllMocks();
  });

  it('creates snapshot', () => {
    const { asFragment } = render(<CompatibilityLevelInfoModal />);
    expect(asFragment()).toMatchSnapshot();
  });

  describe('Render', () => {
    it('renders component', () => {
      render(<CompatibilityLevelInfoModal />);
      expect(screen.getByText('Capability level')).toBeInTheDocument();
    });

    it('opens modal', () => {
      render(<CompatibilityLevelInfoModal />);

      expect(screen.getByRole('dialog')).not.toHaveClass('active');
      const btn = screen.getByRole('button', { name: /Open modal/ });
      userEvent.click(btn);

      expect(screen.getByRole('dialog')).toHaveClass('active');
      expect(screen.getByAltText('Capability Level Diagram')).toBeInTheDocument();
    });
  });
});
